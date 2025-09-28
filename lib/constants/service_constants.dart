import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/customer_model.dart';

class WorkerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique worker ID
  static Future<String> generateWorkerId() async {
    // Get the count of existing workers to generate sequential ID
    QuerySnapshot workerCount = await _firestore.collection('workers').get();
    int count = workerCount.docs.length + 1;

    // Format: HM_XXXX (4 digits)
    String workerId = 'HM_${count.toString().padLeft(4, '0')}';

    // Check if ID already exists, if so increment
    while (await _workerIdExists(workerId)) {
      count++;
      workerId = 'HM_${count.toString().padLeft(4, '0')}';
    }

    return workerId;
  }

  // Check if worker ID exists
  static Future<bool> _workerIdExists(String workerId) async {
    QuerySnapshot existing = await _firestore
        .collection('workers')
        .where('worker_id', isEqualTo: workerId)
        .get();
    return existing.docs.isNotEmpty;
  }

  // Save worker to database
  static Future<void> saveWorker(WorkerModel worker) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Save worker document with user UID as document ID
      await _firestore
          .collection('workers')
          .doc(user.uid)
          .set(worker.toFirestore());

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'accountType': 'service_provider',
        'workerId': worker.workerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save worker profile: ${e.toString()}');
    }
  }

  // Get worker by user ID
  static Future<WorkerModel?> getWorkerByUserId(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('workers').doc(userId).get();

      if (doc.exists) {
        return WorkerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch worker: ${e.toString()}');
    }
  }

  // Update worker profile
  static Future<void> updateWorker(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['last_active'] = FieldValue.serverTimestamp();
      await _firestore.collection('workers').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update worker: ${e.toString()}');
    }
  }

  // Search workers by service type
  static Future<List<WorkerModel>> searchWorkersByService(
      String serviceType) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('workers')
          .where('service_type', isEqualTo: serviceType)
          .where('verified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search workers: ${e.toString()}');
    }
  }

  // Get workers by location radius
  static Future<List<WorkerModel>> getWorkersByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? serviceType,
  }) async {
    try {
      Query query = _firestore.collection('workers');

      if (serviceType != null) {
        query = query.where('service_type', isEqualTo: serviceType);
      }

      QuerySnapshot snapshot = await query.get();

      List<WorkerModel> workers =
          snapshot.docs.map((doc) => WorkerModel.fromFirestore(doc)).toList();

      // Filter by distance (simple calculation - for production, use more accurate geospatial queries)
      return workers.where((worker) {
        double distance = _calculateDistance(
          latitude,
          longitude,
          worker.location.latitude,
          worker.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get workers by location: ${e.toString()}');
    }
  }

  // Simple distance calculation (Haversine formula simplified)
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLon / 2).sin() * (dLon / 2).sin();

    double c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

class CustomerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique customer ID
  static Future<String> generateCustomerId() async {
    // Get the count of existing customers to generate sequential ID
    QuerySnapshot customerCount =
        await _firestore.collection('customers').get();
    int count = customerCount.docs.length + 1;

    // Format: CUST_XXXX (4 digits)
    String customerId = 'CUST_${count.toString().padLeft(4, '0')}';

    // Check if ID already exists, if so increment
    while (await _customerIdExists(customerId)) {
      count++;
      customerId = 'CUST_${count.toString().padLeft(4, '0')}';
    }

    return customerId;
  }

  // Check if customer ID exists
  static Future<bool> _customerIdExists(String customerId) async {
    QuerySnapshot existing = await _firestore
        .collection('customers')
        .where('customer_id', isEqualTo: customerId)
        .get();
    return existing.docs.isNotEmpty;
  }

  // Save customer to database
  static Future<void> saveCustomer(CustomerModel customer) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Save customer document with user UID as document ID
      await _firestore
          .collection('customers')
          .doc(user.uid)
          .set(customer.toFirestore());

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'accountType': 'customer',
        'customerId': customer.customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save customer profile: ${e.toString()}');
    }
  }

  // Get customer by user ID
  static Future<CustomerModel?> getCustomerByUserId(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('customers').doc(userId).get();

      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch customer: ${e.toString()}');
    }
  }

  // Update customer profile
  static Future<void> updateCustomer(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['last_active'] = FieldValue.serverTimestamp();
      await _firestore.collection('customers').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update customer: ${e.toString()}');
    }
  }
}
