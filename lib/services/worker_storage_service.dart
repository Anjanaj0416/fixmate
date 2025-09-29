// lib/services/worker_storage_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';
import '../models/worker_model.dart';

class WorkerStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if a worker from ML dataset already exists in Firebase
  static Future<bool> checkWorkerExists(String mlWorkerId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: mlWorkerId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking worker existence: $e');
      return false;
    }
  }

  /// Get Firebase UID of an existing worker by their ML worker ID
  static Future<String> getWorkerFirebaseUid(String mlWorkerId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: mlWorkerId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Worker not found in database');
      }

      return query.docs.first.id;
    } catch (e) {
      throw Exception('Failed to get worker Firebase UID: $e');
    }
  }

  /// Store worker from ML dataset to Firebase
  static Future<String> storeWorkerFromML({
    required MLWorker mlWorker,
  }) async {
    try {
      bool exists = await checkWorkerExists(mlWorker.workerId);
      if (exists) {
        print('Worker ${mlWorker.workerId} already exists');
        return await getWorkerFirebaseUid(mlWorker.workerId);
      }

      String workerEmail = '${mlWorker.workerId}@fixmate.worker'.toLowerCase();
      String defaultPassword = '123456';

      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: workerEmail,
          password: defaultPassword,
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: workerEmail,
            password: defaultPassword,
          );
          await _auth.signOut();
        } else {
          throw e;
        }
      }

      String workerUid = userCredential!.user!.uid;
      await _auth.signOut();

      await _firestore.collection('users').doc(workerUid).set({
        'email': workerEmail,
        'name': mlWorker.workerName,
        'phone': mlWorker.phoneNumber,
        'accountType': 'service_provider',
        'workerId': mlWorker.workerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'fromMLDataset': true,
      });

      WorkerModel worker = _convertMLWorkerToWorkerModel(mlWorker);
      await _firestore
          .collection('workers')
          .doc(workerUid)
          .set(worker.toFirestore());

      print('✅ Successfully stored worker ${mlWorker.workerId}');
      return workerUid;
    } catch (e) {
      print('❌ Error storing worker: $e');
      throw Exception('Failed to store worker: $e');
    }
  }

  static WorkerModel _convertMLWorkerToWorkerModel(MLWorker mlWorker) {
    Map<String, dynamic> locationCoords = _getCityCoordinates(mlWorker.city);

    List<String> nameParts = mlWorker.workerName.split(' ');
    String firstName =
        nameParts.isNotEmpty ? nameParts.first : mlWorker.workerName;
    String lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return WorkerModel(
      workerId: mlWorker.workerId,
      workerName: mlWorker.workerName,
      firstName: firstName,
      lastName: lastName,
      serviceType: mlWorker.serviceType,
      serviceCategory: _getServiceCategory(mlWorker.serviceType),
      businessName: '${mlWorker.workerName} Services',
      location: WorkerLocation(
        latitude: locationCoords['latitude'],
        longitude: locationCoords['longitude'],
        city: mlWorker.city,
        state: _getStateFromCity(mlWorker.city),
        postalCode: '',
      ),
      rating: mlWorker.rating,
      experienceYears: mlWorker.experienceYears,
      jobsCompleted: 0,
      successRate: mlWorker.rating * 20,
      pricing: WorkerPricing(
        dailyWageLkr: mlWorker.dailyWageLkr.toDouble(),
        halfDayRateLkr: (mlWorker.dailyWageLkr / 2).toDouble(),
        minimumChargeLkr: 500.0,
        emergencyRateMultiplier: 1.5,
        overtimeHourlyLkr: (mlWorker.dailyWageLkr / 8).toDouble(),
      ),
      availability: WorkerAvailability(
        availableToday: true,
        availableWeekends: true,
        emergencyService: true,
        workingHours: '8:00 AM - 6:00 PM',
        responseTimeMinutes: 30,
      ),
      capabilities: WorkerCapabilities(
        toolsOwned: true,
        vehicleAvailable: mlWorker.distanceKm > 10,
        certified: mlWorker.experienceYears > 5,
        insurance: mlWorker.experienceYears > 3,
        languages: ['English', 'Sinhala'],
      ),
      contact: WorkerContact(
        phoneNumber: mlWorker.phoneNumber,
        whatsappAvailable: true,
        email: '${mlWorker.workerId}@fixmate.worker'.toLowerCase(),
      ),
      profile: WorkerProfile(
        bio: mlWorker.bio,
        specializations: _getSpecializations(mlWorker.serviceType),
        serviceRadiusKm: 15.0,
      ),
      verified: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  static Map<String, dynamic> _getCityCoordinates(String city) {
    final Map<String, Map<String, double>> cityCoords = {
      'colombo': {'latitude': 6.9271, 'longitude': 79.8612},
      'kandy': {'latitude': 7.2906, 'longitude': 80.6337},
      'galle': {'latitude': 6.0535, 'longitude': 80.2210},
      'negombo': {'latitude': 7.2084, 'longitude': 79.8380},
      'jaffna': {'latitude': 9.6615, 'longitude': 80.0255},
    };
    return cityCoords[city.toLowerCase()] ??
        {'latitude': 6.9271, 'longitude': 79.8612};
  }

  static String _getStateFromCity(String city) {
    final Map<String, String> cityToState = {
      'colombo': 'Western',
      'kandy': 'Central',
      'galle': 'Southern',
    };
    return cityToState[city.toLowerCase()] ?? 'Western';
  }

  static String _getServiceCategory(String serviceType) {
    if (serviceType.contains('plumb')) return 'plumbing_installation';
    if (serviceType.contains('electric')) return 'electrical_installation';
    if (serviceType.contains('carpent')) return 'carpentry_furniture';
    return 'general_services';
  }

  static List<String> _getSpecializations(String serviceType) {
    if (serviceType.contains('plumb')) return ['Pipe Repair', 'Drain Cleaning'];
    if (serviceType.contains('electric'))
      return ['Wiring', 'Circuit Installation'];
    return ['General Services'];
  }
}
