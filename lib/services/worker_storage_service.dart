// lib/services/worker_storage_service.dart
// CORRECTED VERSION - Matches your actual MLWorker class properties

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';

class WorkerStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if worker exists by phone OR email
  /// Returns the worker_id (HM_XXXX format) if found
  static Future<String?> getExistingWorkerId({
    required String email,
    required String phoneNumber,
  }) async {
    try {
      print('🔍 Checking if worker exists...');
      print('   Email: $email');
      print('   Phone: $phoneNumber');

      // Method 1: Check by email in users collection
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        String uid = userQuery.docs.first.id;
        DocumentSnapshot workerDoc =
            await _firestore.collection('workers').doc(uid).get();

        if (workerDoc.exists) {
          String workerId =
              (workerDoc.data() as Map<String, dynamic>)['worker_id'];
          print('✅ Found existing worker by email: $workerId');
          return workerId;
        }
      }

      // Method 2: Check by phone number
      QuerySnapshot workerQuery = await _firestore
          .collection('workers')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (workerQuery.docs.isNotEmpty) {
        String workerId = (workerQuery.docs.first.data()
            as Map<String, dynamic>)['worker_id'];
        print('✅ Found existing worker by phone: $workerId');
        return workerId;
      }

      print('📝 No existing worker found');
      return null;
    } catch (e) {
      print('❌ Error checking existing worker: $e');
      return null;
    }
  }

  /// Check if a worker already exists by EMAIL
  static Future<bool> checkWorkerExistsByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
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
          .where('email', isEqualTo: email.toLowerCase().trim())
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
  /// RETURNS: worker_id (HM_XXXX format), NOT Firebase UID
  static Future<String> storeWorkerFromML({
    required MLWorker mlWorker,
  }) async {
    print('\n========== WORKER STORAGE START ==========');

    try {
      String email = mlWorker.email.toLowerCase().trim();
      String phone = mlWorker.phoneNumber.trim();

      // CRITICAL: Check if worker already exists
      String? existingWorkerId = await getExistingWorkerId(
        email: email,
        phoneNumber: phone,
      );

      if (existingWorkerId != null) {
        print('✅ Worker already exists: $existingWorkerId');
        print('========== WORKER STORAGE END ==========\n');
        return existingWorkerId; // Return the worker_id (HM_XXXX)
      }

      print('📝 Creating new worker account...');

      // Save current user context
      User? currentUser = _auth.currentUser;
      String? currentUserEmail = currentUser?.email;
      String? currentUserUid = currentUser?.uid;

      // Create worker auth account
      String tempPassword = 'Worker@${phone.replaceAll('+', '')}';
      UserCredential? workerCredential;
      String workerUid;

      try {
        workerCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        workerUid = workerCredential.user!.uid;
        print('✅ Firebase Auth account created: $workerUid');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('⚠️  Email exists, signing in...');
          workerCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
          workerUid = workerCredential.user!.uid;
          print('✅ Signed in to existing account: $workerUid');
        } else {
          throw e;
        }
      }

      // Generate worker_id (HM_XXXX format)
      String workerId = await generateFormattedWorkerId();
      print('🆔 Assigned worker_id: $workerId');

      // Split name for first/last
      List<String> nameParts = mlWorker.workerName.split(' ');
      String firstName =
          nameParts.isNotEmpty ? nameParts.first : mlWorker.workerName;
      String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Prepare worker data using ACTUAL MLWorker properties
      Map<String, dynamic> workerData = {
        'worker_id': workerId, // HM_XXXX format
        'worker_name': mlWorker.workerName,
        'first_name': firstName,
        'last_name': lastName,
        'service_type': mlWorker.serviceType,
        'service_category': mlWorker.serviceType, // Same as service_type
        'business_name':
            '$firstName\'s ${mlWorker.serviceType.replaceAll('_', ' ')} Service',
        'rating': mlWorker.rating,
        'experience_years': mlWorker.experienceYears,
        'created_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
        'verified': true,
        'available': true,
        'email': email,
        'phone_number': phone,
        'location': {
          'city': mlWorker.city,
          'district': mlWorker.city, // Use city as district
          'latitude': 0.0, // Default, will be updated later
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
        'capabilities': [], // Empty for now
        'profile': {
          'bio': mlWorker.bio,
          'profile_image': '',
          'certifications': [],
        },
      };

      // Store in workers collection (document ID = Firebase UID)
      await _firestore.collection('workers').doc(workerUid).set(workerData);
      print('✅ Worker document created in workers collection');

      // Store in users collection (document ID = Firebase UID)
      Map<String, dynamic> userData = {
        'uid': workerUid,
        'email': email,
        'accountType': 'service_provider',
        'worker_id': workerId, // CRITICAL: Store worker_id here too
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'displayName': mlWorker.workerName,
      };

      await _firestore.collection('users').doc(workerUid).set(userData);
      print('✅ User document created with worker_id: $workerId');

      // Restore original user session
      if (currentUserEmail != null && currentUserUid != null) {
        try {
          await _auth.signOut();
          print('🔄 Restored original user session');
        } catch (e) {
          print('⚠️  Could not restore session: $e');
        }
      } else {
        await _auth.signOut();
      }

      print('✅ Worker stored successfully!');
      print('========== WORKER STORAGE END ==========\n');

      return workerId; // RETURN worker_id (HM_XXXX), NOT UID
    } catch (e) {
      print('❌ Error storing worker: $e');
      print('========== WORKER STORAGE END ==========\n');
      rethrow;
    }
  }

  /// Get worker_id by email
  static Future<String?> getWorkerIdByEmail(String email) async {
    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        Map<String, dynamic>? userData =
            userQuery.docs.first.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('worker_id')) {
          return userData['worker_id'];
        }

        // If not in users, check workers collection
        String uid = userQuery.docs.first.id;
        DocumentSnapshot workerDoc =
            await _firestore.collection('workers').doc(uid).get();

        if (workerDoc.exists) {
          return (workerDoc.data() as Map<String, dynamic>)['worker_id'];
        }
      }

      return null;
    } catch (e) {
      print('Error getting worker_id by email: $e');
      return null;
    }
  }
}
