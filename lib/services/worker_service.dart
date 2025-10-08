// lib/services/worker_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import 'dart:math' as math;

class WorkerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save worker profile
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

  // Search workers with filtering
  static Future<List<WorkerModel>> searchWorkers({
    required String serviceType,
    String? city,
    String? serviceCategory,
    String? specialization,
    double? maxDistance,
    double? userLat,
    double? userLng,
  }) async {
    try {
      print('DEBUG: Searching workers with serviceType: $serviceType');

      Query query = _firestore.collection('workers');

      // BRANCH 1: Filter by service type (always applied)
      query = query.where('service_type', isEqualTo: serviceType);

      // BRANCH 2: Filter by city if provided
      if (city != null && city.isNotEmpty) {
        query = query.where('location.city', isEqualTo: city);
      }

      // BRANCH 3: Filter by service category if provided
      if (serviceCategory != null && serviceCategory.isNotEmpty) {
        query = query.where('service_category', isEqualTo: serviceCategory);
      }

      print('DEBUG: Executing query...');
      QuerySnapshot querySnapshot = await query.get();
      print('DEBUG: Found ${querySnapshot.docs.length} workers');

      // BRANCH 4: Empty results - try fallback broader search
      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: No workers found with filters, trying broader search...');
        query = _firestore.collection('workers');
        query = query.where('service_type', isEqualTo: serviceType);
        querySnapshot = await query.get();
        print(
            'DEBUG: Broader search found ${querySnapshot.docs.length} workers');
      }

      List<WorkerModel> workers = [];

      // BRANCH 5: Parse documents
      for (var doc in querySnapshot.docs) {
        try {
          WorkerModel worker = WorkerModel.fromFirestore(doc);
          workers.add(worker);
        } catch (e) {
          print('DEBUG: Error parsing worker ${doc.id}: $e');
        }
      }

      // BRANCH 6: Distance calculation loop if location provided
      if (maxDistance != null && userLat != null && userLng != null) {
        workers = workers.where((worker) {
          if (worker.location.latitude != null &&
              worker.location.longitude != null) {
            double distance = _calculateDistance(
              userLat,
              userLng,
              worker.location.latitude!,
              worker.location.longitude!,
            );
            // BRANCH 7: MaxDistance filtering
            return distance <= maxDistance;
          }
          return true; // Include workers without location data
        }).toList();
      }

      print('DEBUG: Returning ${workers.length} workers after filtering');
      return workers;
    } catch (e) {
      // BRANCH 8: Error handling
      print('DEBUG: Error in searchWorkers: $e');
      throw Exception('Failed to search workers: ${e.toString()}');
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // Get all workers
  static Future<List<WorkerModel>> getAllWorkers() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('workers').get();

      List<WorkerModel> workers = [];
      for (var doc in querySnapshot.docs) {
        try {
          workers.add(WorkerModel.fromFirestore(doc));
        } catch (e) {
          print('Error parsing worker ${doc.id}: $e');
        }
      }

      return workers;
    } catch (e) {
      throw Exception('Failed to get all workers: ${e.toString()}');
    }
  }

  // Get worker by worker ID
  static Future<WorkerModel?> getWorkerByWorkerId(String workerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return WorkerModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch worker: ${e.toString()}');
    }
  }
}
