// lib/services/worker_storage_service.dart
// CORRECTED VERSION - Matches your actual MLWorker structure
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';
import '../models/worker_model.dart';

class WorkerStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if a worker already exists by EMAIL
  static Future<bool> checkWorkerExistsByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking worker existence by email: $e');
      return false;
    }
  }

  /// Get Firebase UID by worker email
  static Future<String?> getWorkerUidByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query.docs.first.id;
    } catch (e) {
      print('Error getting worker UID by email: $e');
      return null;
    }
  }

  /// Generate formatted worker ID with sequential ordering
  static Future<String> generateFormattedWorkerId() async {
    try {
      QuerySnapshot workersSnapshot = await _firestore
          .collection('workers')
          .orderBy('worker_id', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;

      if (workersSnapshot.docs.isNotEmpty) {
        String lastWorkerId = workersSnapshot.docs.first.get('worker_id');
        String numberPart = lastWorkerId.replaceAll('HM_', '');
        int lastNumber = int.tryParse(numberPart) ?? 0;
        nextNumber = lastNumber + 1;
      }

      String formattedId = 'HM_${nextNumber.toString().padLeft(4, '0')}';
      print('✅ Generated formatted worker ID: $formattedId');
      return formattedId;
    } catch (e) {
      print('❌ Error generating worker ID: $e');
      return 'HM_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Store worker from ML dataset to Firebase
  /// CRITICAL FIX: Removed signOut() calls to ensure data persists
  static Future<String> storeWorkerFromML({
    required MLWorker mlWorker,
  }) async {
    // Save currently logged-in user info
    User? currentUser = _auth.currentUser;
    String? currentUserEmail = currentUser?.email;
    String? currentUserId = currentUser?.uid;

    print('\n========== WORKER STORAGE START ==========');
    print('💾 Current logged-in user: $currentUserEmail (UID: $currentUserId)');

    try {
      // Use email from ML model
      String workerEmail = mlWorker.email.toLowerCase().trim();
      String defaultPassword = '123456';

      print('📧 Processing worker email: $workerEmail');

      // Check if worker already exists by EMAIL
      bool exists = await checkWorkerExistsByEmail(workerEmail);

      if (exists) {
        print('⚠️  Worker with email $workerEmail already exists');
        String? existingUid = await getWorkerUidByEmail(workerEmail);
        if (existingUid != null) {
          print('✅ Found existing worker UID: $existingUid');
          print('========== WORKER STORAGE END ==========\n');
          return existingUid;
        }
      }

      // CRITICAL FIX: Create worker account WITHOUT signing out immediately
      UserCredential? userCredential;
      String workerUid = '';

      try {
        print('🔐 Creating Firebase Auth account for worker...');

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: workerEmail,
          password: defaultPassword,
        );

        workerUid = userCredential.user!.uid;
        print('✅ Firebase Auth account created with UID: $workerUid');

        // REMOVED: await _auth.signOut(); ← THIS WAS CAUSING THE PROBLEM!
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('📝 Email already in use, getting existing UID...');

          String? existingUid = await getWorkerUidByEmail(workerEmail);
          if (existingUid != null) {
            print('✅ Found existing worker UID: $existingUid');
            return existingUid;
          } else {
            throw Exception('Worker email exists but UID not found');
          }
        } else {
          print('❌ Error creating auth account: $e');
          throw e;
        }
      }

      // Generate formatted worker ID
      String formattedWorkerId = await generateFormattedWorkerId();
      print('🆔 Assigned worker ID: $formattedWorkerId');

      // Split name for first/last name
      List<String> nameParts = mlWorker.workerName.split(' ');
      String firstName =
          nameParts.isNotEmpty ? nameParts.first : mlWorker.workerName;
      String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Get city coordinates
      Map<String, dynamic> locationCoords = _getCityCoordinates(mlWorker.city);

      // STEP 1: Create user document
      print('📝 Creating user document...');
      await _firestore.collection('users').doc(workerUid).set({
        'email': workerEmail,
        'name': mlWorker.workerName,
        'phone': mlWorker.phoneNumber,
        'accountType': 'service_provider',
        'workerId': formattedWorkerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'fromMLDataset': true,
      });
      print('✅ User document created');

      // STEP 2: Create worker document - Using MLWorker's simple structure
      print('📝 Creating worker document...');
      await _firestore.collection('workers').doc(workerUid).set({
        'worker_id': formattedWorkerId,
        'worker_name': mlWorker.workerName,
        'first_name': firstName,
        'last_name': lastName,
        'email': workerEmail,
        'phone_number': mlWorker.phoneNumber,

        'service_type': mlWorker.serviceType,
        'service_category': _getServiceCategory(mlWorker.serviceType),
        'business_name':
            '${firstName}\'s ${_getServiceDisplayName(mlWorker.serviceType)}',

        // Location - derived from city
        'location': {
          'latitude': locationCoords['latitude'],
          'longitude': locationCoords['longitude'],
          'city': mlWorker.city,
          'state': locationCoords['state'],
          'postal_code': '',
        },

        // Basic worker info from ML model
        'rating': mlWorker.rating,
        'experience_years': mlWorker.experienceYears,
        'jobs_completed': 0,
        'success_rate': 0.0,

        // Pricing - calculated from dailyWageLkr
        'pricing': {
          'daily_wage_lkr': mlWorker.dailyWageLkr.toDouble(),
          'half_day_rate_lkr': (mlWorker.dailyWageLkr * 0.6).toDouble(),
          'minimum_charge_lkr': (mlWorker.dailyWageLkr * 0.3).toDouble(),
          'emergency_rate_multiplier': 1.5,
          'overtime_hourly_lkr': (mlWorker.dailyWageLkr / 8 * 1.5).toDouble(),
        },

        // Default availability
        'availability': {
          'available_today': true,
          'available_weekends': true,
          'emergency_service': true,
          'working_hours': '09:00 - 17:00',
          'response_time_minutes': 30,
        },

        // Default capabilities
        'capabilities': {
          'tools_owned': true,
          'vehicle_available': false,
          'certified': false,
          'insurance': false,
          'languages': ['Sinhala', 'English'],
        },

        // Contact info
        'contact': {
          'phone_number': mlWorker.phoneNumber,
          'whatsapp_available': true,
          'email': workerEmail,
          'website': null,
        },

        // Profile info
        'profile': {
          'bio': mlWorker.bio,
          'specializations': [mlWorker.serviceType],
          'service_radius_km': 25.0,
        },

        'verified': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      });
      print('✅ Worker document created');

      print('✅ Successfully stored worker $formattedWorkerId ($workerEmail)');
      print(
          '⚠️  NOTE: Customer is now signed out! They need to re-authenticate.');
      print('========== WORKER STORAGE END ==========\n');

      return workerUid;
    } catch (e) {
      print('❌ Error storing worker: $e');
      print('========== WORKER STORAGE END ==========\n');
      throw Exception('Failed to store worker: $e');
    }
  }

  /// Get city coordinates for Sri Lankan cities
  static Map<String, dynamic> _getCityCoordinates(String city) {
    final Map<String, Map<String, dynamic>> cityCoords = {
      'colombo': {'latitude': 6.9271, 'longitude': 79.8612, 'state': 'Western'},
      'kandy': {'latitude': 7.2906, 'longitude': 80.6337, 'state': 'Central'},
      'galle': {'latitude': 6.0535, 'longitude': 80.2210, 'state': 'Southern'},
      'jaffna': {'latitude': 9.6615, 'longitude': 80.0255, 'state': 'Northern'},
      'negombo': {'latitude': 7.2008, 'longitude': 79.8358, 'state': 'Western'},
      'batticaloa': {
        'latitude': 7.7310,
        'longitude': 81.6747,
        'state': 'Eastern'
      },
      'matara': {'latitude': 5.9549, 'longitude': 80.5550, 'state': 'Southern'},
      'kurunegala': {
        'latitude': 7.4863,
        'longitude': 80.3623,
        'state': 'North Western'
      },
      'anuradhapura': {
        'latitude': 8.3114,
        'longitude': 80.4037,
        'state': 'North Central'
      },
      'trincomalee': {
        'latitude': 8.5874,
        'longitude': 81.2152,
        'state': 'Eastern'
      },
    };

    String cityLower = city.toLowerCase().trim();
    return cityCoords[cityLower] ??
        {'latitude': 6.9271, 'longitude': 79.8612, 'state': 'Unknown'};
  }

  /// Get service category from service type
  static String _getServiceCategory(String serviceType) {
    final Map<String, String> categories = {
      'electrical_services': 'home_services',
      'plumbing': 'home_services',
      'carpentry': 'home_services',
      'painting': 'home_services',
      'ac_repair': 'appliance_repair',
      'refrigerator_repair': 'appliance_repair',
      'washing_machine_repair': 'appliance_repair',
      'it_support': 'technical_services',
      'computer_repair': 'technical_services',
    };
    return categories[serviceType] ?? 'general_services';
  }

  /// Get display name for service
  static String _getServiceDisplayName(String serviceType) {
    final Map<String, String> displayNames = {
      'electrical_services': 'Electrical Services',
      'plumbing': 'Plumbing Services',
      'carpentry': 'Carpentry Services',
      'painting': 'Painting Services',
      'ac_repair': 'AC Repair',
      'refrigerator_repair': 'Refrigerator Repair',
      'washing_machine_repair': 'Washing Machine Repair',
      'it_support': 'IT Support',
      'computer_repair': 'Computer Repair',
    };
    return displayNames[serviceType] ?? 'General Services';
  }
}
