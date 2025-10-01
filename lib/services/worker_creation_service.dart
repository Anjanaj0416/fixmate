// lib/services/worker_creation_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ml_service.dart';

class WorkerCreationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create worker account using Cloud Function
  /// Returns: worker_id (HM_XXXX format)
  static Future<String> createWorkerFromML({
    required MLWorker mlWorker,
  }) async {
    print('\n========== CLOUD FUNCTION WORKER CREATION START ==========');

    try {
      String email = mlWorker.email.toLowerCase().trim();
      String phone = mlWorker.phoneNumber.trim();

      // 1. Check if worker already exists in Firestore
      String? existingWorkerId = await _checkExistingWorker(email, phone);
      if (existingWorkerId != null) {
        print('✅ Worker already exists: $existingWorkerId');
        print('========== CLOUD FUNCTION WORKER CREATION END ==========\n');
        return existingWorkerId;
      }

      print('📝 Calling Cloud Function to create new worker...');

      // 2. Prepare worker data
      List<String> nameParts = mlWorker.workerName.split(' ');
      String firstName =
          nameParts.isNotEmpty ? nameParts.first : mlWorker.workerName;
      String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      Map<String, dynamic> workerData = {
        'worker_name': mlWorker.workerName,
        'first_name': firstName,
        'last_name': lastName,
        'service_type': mlWorker.serviceType,
        'service_category': mlWorker.serviceType,
        'business_name':
            '$firstName\'s ${mlWorker.serviceType.replaceAll('_', ' ')} Service',
        'rating': mlWorker.rating,
        'experience_years': mlWorker.experienceYears,
        'verified': true,
        'available': true,
        'email': email,
        'phone_number': phone,
        'location': {
          'city': mlWorker.city,
          'district': mlWorker.city,
          'latitude': 0.0,
          'longitude': 0.0,
        },
        'pricing': {
          'daily_wage_lkr': mlWorker.dailyWageLkr.toDouble(),
          'half_day_rate_lkr': (mlWorker.dailyWageLkr * 0.6).toDouble(),
          'hourly_rate_lkr': (mlWorker.dailyWageLkr / 8).toDouble(),
          'minimum_charge_lkr': (mlWorker.dailyWageLkr * 0.3).toDouble(),
          'currency': 'LKR',
        },
        'availability': {
          'available_today': true,
          'available_this_week': true,
          'working_hours': {
            'start': '08:00',
            'end': '18:00',
          },
        },
        'capabilities': [],
        'profile': {
          'bio': mlWorker.bio,
          'profile_image': '',
          'certifications': [],
        },
      };

      Map<String, dynamic> userData = {
        'email': email,
        'accountType': 'service_provider',
        'displayName': mlWorker.workerName,
      };

      // 3. Call Cloud Function
      final HttpsCallable callable =
          _functions.httpsCallable('createWorkerAccount');

      final result = await callable.call({
        'email': email,
        'password': '123456', // Default password as required
        'workerData': workerData,
        'userData': userData,
      });

      // 4. Extract result
      Map<String, dynamic> response = Map<String, dynamic>.from(result.data);

      if (response['success'] == true) {
        String workerId = response['workerId'];
        print('✅ Worker created successfully!');
        print('   Worker ID: $workerId');
        print('   Firebase UID: ${response['workerUid']}');
        print('   Already Existed: ${response['alreadyExists']}');
        print('========== CLOUD FUNCTION WORKER CREATION END ==========\n');
        return workerId;
      } else {
        throw Exception('Cloud Function returned success=false');
      }
    } catch (e) {
      print('❌ Error creating worker via Cloud Function: $e');
      print('========== CLOUD FUNCTION WORKER CREATION END ==========\n');
      throw Exception('Failed to create worker account: ${e.toString()}');
    }
  }

  /// Check if worker already exists by email or phone
  static Future<String?> _checkExistingWorker(
      String email, String phone) async {
    try {
      // Check by email
      QuerySnapshot emailQuery = await _firestore
          .collection('workers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return emailQuery.docs.first.get('worker_id');
      }

      // Check by phone
      QuerySnapshot phoneQuery = await _firestore
          .collection('workers')
          .where('phone_number', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        return phoneQuery.docs.first.get('worker_id');
      }

      return null;
    } catch (e) {
      print('Error checking existing worker: $e');
      return null;
    }
  }

  /// Get worker details by worker_id
  static Future<Map<String, dynamic>> getWorkerByWorkerId(
      String workerId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Worker not found: $workerId');
      }

      return query.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get worker details: $e');
    }
  }
}
