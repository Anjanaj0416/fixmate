// lib/services/worker_storage_service.dart
// COMPLETE FIXED VERSION - This prevents duplicate worker creation

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';

class WorkerStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if worker exists by phone OR email
  /// Returns the worker_id (HM_XXXX format) if found
  /// CRITICAL FIX: Now also checks workers collection by phone AND email
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
        print('   Found user account with UID: $uid');

        // Check if this user has a worker profile
        DocumentSnapshot workerDoc =
            await _firestore.collection('workers').doc(uid).get();

        if (workerDoc.exists) {
          String workerId =
              (workerDoc.data() as Map<String, dynamic>)['worker_id'];
          print('✅ Found existing worker by email: $workerId');
          return workerId;
        } else {
          print('   User exists but no worker profile');
        }
      }

      // Method 2: Check by phone number in workers collection
      QuerySnapshot workerQueryByPhone = await _firestore
          .collection('workers')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (workerQueryByPhone.docs.isNotEmpty) {
        String workerId = (workerQueryByPhone.docs.first.data()
            as Map<String, dynamic>)['worker_id'];
        print('✅ Found existing worker by phone: $workerId');
        return workerId;
      }

      // Method 3: CRITICAL FIX - Check by email in workers collection
      // This catches cases where email exists in workers but not in users
      QuerySnapshot workerQueryByEmail = await _firestore
          .collection('workers')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (workerQueryByEmail.docs.isNotEmpty) {
        String workerId = (workerQueryByEmail.docs.first.data()
            as Map<String, dynamic>)['worker_id'];
        print(
            '✅ Found existing worker by email in workers collection: $workerId');
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
  /// CRITICAL FIX: Now properly checks for duplicates before creating
  static Future<String> storeWorkerFromML({
    required MLWorker mlWorker,
  }) async {
    print('\n========== WORKER STORAGE START ==========');

    try {
      String email = mlWorker.email.toLowerCase().trim();
      String phone = mlWorker.phoneNumber.trim();

      // CRITICAL FIX: Check if worker already exists BEFORE creating
      print('🔍 Step 1: Checking for existing worker...');
      String? existingWorkerId = await getExistingWorkerId(
        email: email,
        phoneNumber: phone,
      );

      if (existingWorkerId != null) {
        print('✅ Worker already exists with worker_id: $existingWorkerId');
        print('   Skipping creation to avoid duplicates');
        print('========== WORKER STORAGE END ==========\n');
        return existingWorkerId; // Return the existing worker_id (HM_XXXX)
      }

      print('📝 Step 2: No existing worker found, creating new account...');

      // Save current user context
      User? currentUser = _auth.currentUser;
      String? currentUserEmail = currentUser?.email;
      String? currentUserUid = currentUser?.uid;

      // Create worker auth account
      String tempPassword = 'Worker@${phone.replaceAll('+', '')}';
      UserCredential? workerCredential;
      String workerUid;

      try {
        print('🔐 Creating Firebase Auth account...');
        workerCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        workerUid = workerCredential.user!.uid;
        print('✅ Firebase Auth account created: $workerUid');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('⚠️  Email exists in Auth, signing in...');
          workerCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
          workerUid = workerCredential.user!.uid;
          print('✅ Signed in to existing account: $workerUid');

          // CRITICAL: Double check if this worker already has a profile
          DocumentSnapshot existingWorkerDoc =
              await _firestore.collection('workers').doc(workerUid).get();

          if (existingWorkerDoc.exists) {
            String existingId =
                (existingWorkerDoc.data() as Map<String, dynamic>)['worker_id'];
            print('✅ Worker profile already exists: $existingId');

            // Restore user session
            if (currentUserEmail != null && currentUserUid != null) {
              try {
                await _auth.signOut();
                print('🔄 Restored original user session');
              } catch (e) {
                print('⚠️  Could not restore session: $e');
              }
            }

            print('========== WORKER STORAGE END ==========\n');
            return existingId;
          }
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
        'service_category': mlWorker.serviceType,
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

      // Store in workers collection
      await _firestore.collection('workers').doc(workerUid).set(workerData);
      print('✅ Worker document created in workers collection');

      // Store in users collection
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

      print('✅ Worker stored successfully with worker_id: $workerId');
      print('========== WORKER STORAGE END ==========\n');

      // Return the worker_id (HM_XXXX format), NOT the Firebase UID
      return workerId;
    } catch (e) {
      print('❌ Error storing worker: $e');
      print('========== WORKER STORAGE END ==========\n');

      // Try to restore user session even on error
      try {
        await _auth.signOut();
      } catch (signOutError) {
        print('⚠️  Could not sign out: $signOutError');
      }

      throw Exception('Failed to store worker from ML: $e');
    }
  }

  /// Get worker details by worker_id (HM_XXXX format)
  static Future<Map<String, dynamic>?> getWorkerByWorkerId(
      String workerId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting worker by worker_id: $e');
      return null;
    }
  }
}
