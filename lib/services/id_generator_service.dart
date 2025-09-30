// lib/services/id_generator_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IDGeneratorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate structured Customer ID: CU_0001
  static Future<String> generateCustomerId() async {
    return await _generateSequentialId('CU', 'customers', 'customer_id');
  }

  /// Generate structured Worker ID: HM_0001
  static Future<String> generateWorkerId() async {
    return await _generateSequentialId('HM', 'workers', 'worker_id');
  }

  /// Generate structured Booking ID: BOOK_0001
  static Future<String> generateBookingId() async {
    return await _generateSequentialId('BOOK', 'bookings', 'booking_id');
  }

  /// Generate structured User ID: USR_0001
  static Future<String> generateUserId() async {
    return await _generateSequentialId('USR', 'users', 'user_id');
  }

  /// Generic method to generate sequential IDs
  static Future<String> _generateSequentialId(
    String prefix,
    String collectionName,
    String idFieldName,
  ) async {
    try {
      // Get the counter document
      DocumentReference counterDoc =
          _firestore.collection('counters').doc('${collectionName}_counter');

      // Use transaction to ensure atomicity
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(counterDoc);

        int nextNumber;
        if (!snapshot.exists) {
          // Initialize counter if it doesn't exist
          nextNumber = 1;
          transaction.set(counterDoc, {
            'current_count': nextNumber,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          // Get current count and increment
          nextNumber =
              (snapshot.data() as Map<String, dynamic>)['current_count'] + 1;
          transaction.update(counterDoc, {
            'current_count': nextNumber,
            'last_updated': FieldValue.serverTimestamp(),
          });
        }

        // Format the ID based on prefix
        String formattedId =
            '${prefix}_${nextNumber.toString().padLeft(4, '0')}';

        // Verify uniqueness (extra safety check)
        QuerySnapshot existing = await _firestore
            .collection(collectionName)
            .where(idFieldName, isEqualTo: formattedId)
            .get();

        if (existing.docs.isNotEmpty) {
          // If somehow the ID exists, recursively try again
          throw Exception('ID collision detected, retrying...');
        }

        return formattedId;
      });
    } catch (e) {
      print('Error generating ID: $e');
      // If transaction fails, try again
      if (e.toString().contains('collision')) {
        return await _generateSequentialId(prefix, collectionName, idFieldName);
      }
      rethrow;
    }
  }

  /// Verify if an ID exists in a collection
  static Future<bool> idExists(
    String collectionName,
    String idFieldName,
    String id,
  ) async {
    QuerySnapshot query = await _firestore
        .collection(collectionName)
        .where(idFieldName, isEqualTo: id)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Get next available number for a given prefix (without creating it)
  static Future<int> getNextNumber(String collectionName) async {
    DocumentSnapshot counterDoc = await _firestore
        .collection('counters')
        .doc('${collectionName}_counter')
        .get();

    if (!counterDoc.exists) {
      return 1;
    }

    return (counterDoc.data() as Map<String, dynamic>)['current_count'] + 1;
  }
}
