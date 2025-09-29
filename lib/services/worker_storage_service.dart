// lib/services/worker_storage_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';
import '../models/worker_model.dart';

class WorkerStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if a worker already exists by EMAIL (not worker_id)
  /// This prevents duplicate accounts for the same worker
  static Future<bool> checkWorkerExistsByEmail(String email) async {
    try {
      // Check in users collection by email
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
  /// Format: HM_0001, HM_0002, HM_0003, etc.
  static Future<String> generateFormattedWorkerId() async {
    try {
      // Get all existing workers and find the highest ID number
      QuerySnapshot workersSnapshot = await _firestore
          .collection('workers')
          .orderBy('worker_id', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;

      if (workersSnapshot.docs.isNotEmpty) {
        String lastWorkerId = workersSnapshot.docs.first.get('worker_id');
        // Extract number from format HM_XXXX
        String numberPart = lastWorkerId.replaceAll('HM_', '');
        int lastNumber = int.tryParse(numberPart) ?? 0;
        nextNumber = lastNumber + 1;
      }

      // Format with leading zeros (4 digits)
      String formattedId = 'HM_${nextNumber.toString().padLeft(4, '0')}';

      print('✅ Generated formatted worker ID: $formattedId');
      return formattedId;
    } catch (e) {
      print('❌ Error generating worker ID: $e');
      // Fallback to timestamp-based ID
      return 'HM_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Store worker from ML dataset to Firebase
  /// Uses worker's actual email from dataset instead of generating new one
  static Future<String> storeWorkerFromML({
    required MLWorker mlWorker,
  }) async {
    try {
      // Extract email from dataset - assuming it's in the format or can be derived
      // If the dataset has email field directly, use: mlWorker.email
      // If not, you need to modify MLWorker class to include email field
      String workerEmail = _extractWorkerEmail(mlWorker);
      String defaultPassword = '123456';

      print('📧 Processing worker email: $workerEmail');

      // Check if worker already exists by EMAIL
      bool exists = await checkWorkerExistsByEmail(workerEmail);

      if (exists) {
        print('⚠️  Worker with email $workerEmail already exists');
        String? existingUid = await getWorkerUidByEmail(workerEmail);
        if (existingUid != null) {
          print('✅ Found existing worker UID: $existingUid');
          return existingUid;
        }
      }

      // Create or sign in to Firebase Auth account
      UserCredential? userCredential;
      try {
        print('🔐 Creating Firebase Auth account...');
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: workerEmail,
          password: defaultPassword,
        );
        print('✅ Firebase Auth account created');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('📝 Email already in use, signing in...');
          userCredential = await _auth.signInWithEmailAndPassword(
            email: workerEmail,
            password: defaultPassword,
          );
          await _auth.signOut();
          print('✅ Signed in to existing account');
        } else {
          throw e;
        }
      }

      String workerUid = userCredential!.user!.uid;
      await _auth.signOut();

      // Generate formatted worker ID
      String formattedWorkerId = await generateFormattedWorkerId();

      print('🆔 Assigned worker ID: $formattedWorkerId');

      // Create user document with proper structure
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

      // Convert ML worker to WorkerModel following exact structure
      WorkerModel worker = _convertMLWorkerToWorkerModel(
        mlWorker,
        formattedWorkerId,
        workerEmail,
      );

      // Store in workers collection following the WorkerModel structure
      await _firestore
          .collection('workers')
          .doc(workerUid)
          .set(worker.toFirestore());

      print('✅ Successfully stored worker $formattedWorkerId ($workerEmail)');
      return workerUid;
    } catch (e) {
      print('❌ Error storing worker: $e');
      throw Exception('Failed to store worker: $e');
    }
  }

  /// Extract worker email from ML dataset
  /// IMPORTANT: Modify this based on your actual dataset structure
  static String _extractWorkerEmail(MLWorker mlWorker) {
    // OPTION 1: If email exists directly in the dataset
    // Uncomment and modify MLWorker class to include email field
    // return mlWorker.email;

    // OPTION 2: If you need to derive email from worker data
    // For example, if the dataset has a contact field with email
    // return mlWorker.contact['email'];

    // OPTION 3: Fallback - generate from worker ID (modify as needed)
    // This should be replaced with actual email from dataset
    return '${mlWorker.workerId.toLowerCase()}@fixmate.worker';

    // TODO: Replace above with actual email extraction from your dataset
    // Example: if dataset JSON has "contact": {"email": "worker@example.com"}
    // then add email field to MLWorker class and use it here
  }

  /// Convert MLWorker to WorkerModel with proper structure
  static WorkerModel _convertMLWorkerToWorkerModel(
    MLWorker mlWorker,
    String formattedWorkerId,
    String workerEmail,
  ) {
    // Get city coordinates
    Map<String, dynamic> locationCoords = _getCityCoordinates(mlWorker.city);

    // Split name into first and last
    List<String> nameParts = mlWorker.workerName.split(' ');
    String firstName =
        nameParts.isNotEmpty ? nameParts.first : mlWorker.workerName;
    String lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Create WorkerModel following exact structure
    return WorkerModel(
      workerId: formattedWorkerId,
      workerName: mlWorker.workerName,
      firstName: firstName,
      lastName: lastName,
      serviceType: mlWorker.serviceType,
      serviceCategory: _getServiceCategory(mlWorker.serviceType),
      businessName:
          '${firstName}\'s ${_getServiceDisplayName(mlWorker.serviceType)}',

      location: WorkerLocation(
        latitude: locationCoords['latitude'],
        longitude: locationCoords['longitude'],
        city: mlWorker.city,
        state: locationCoords['state'],
        postalCode: '',
      ),

      rating: mlWorker.rating,
      experienceYears: mlWorker.experienceYears,
      jobsCompleted: 0,
      successRate: 0.0,

      pricing: WorkerPricing(
        dailyWageLkr: mlWorker.dailyWageLkr.toDouble(),
        halfDayRateLkr: (mlWorker.dailyWageLkr * 0.6).toDouble(),
        minimumChargeLkr: (mlWorker.dailyWageLkr * 0.3).toDouble(),
        emergencyRateMultiplier: 1.5,
        overtimeHourlyLkr: (mlWorker.dailyWageLkr / 8 * 1.5).toDouble(),
      ),

      // FIXED: Use correct WorkerAvailability constructor
      availability: WorkerAvailability(
        availableToday: true,
        availableWeekends: true,
        emergencyService: true,
        workingHours: '09:00 - 17:00',
        responseTimeMinutes: 30,
      ),

      capabilities: WorkerCapabilities(
        toolsOwned: true,
        vehicleAvailable: false,
        certified: false,
        insurance: false,
        languages: ['Sinhala', 'English'],
      ),

      contact: WorkerContact(
        phoneNumber: mlWorker.phoneNumber,
        whatsappAvailable: true,
        email: workerEmail,
      ),

      profile: WorkerProfile(
        bio: mlWorker.bio,
        specializations: [mlWorker.serviceType],
        serviceRadiusKm: 25.0,
      ),

      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      verified: true,
    );
  }

  /// Get city coordinates for Sri Lankan cities
  static Map<String, dynamic> _getCityCoordinates(String city) {
    final Map<String, Map<String, dynamic>> cityCoordinates = {
      'colombo': {'latitude': 6.9271, 'longitude': 79.8612, 'state': 'Western'},
      'kandy': {'latitude': 7.2906, 'longitude': 80.6337, 'state': 'Central'},
      'galle': {'latitude': 6.0535, 'longitude': 80.2210, 'state': 'Southern'},
      'negombo': {'latitude': 7.2084, 'longitude': 79.8380, 'state': 'Western'},
      'jaffna': {'latitude': 9.6615, 'longitude': 80.0255, 'state': 'Northern'},
      'matara': {'latitude': 5.9549, 'longitude': 80.5550, 'state': 'Southern'},
      'kurunegala': {
        'latitude': 7.4818,
        'longitude': 80.3609,
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
      'batticaloa': {
        'latitude': 7.7310,
        'longitude': 81.6747,
        'state': 'Eastern'
      },
    };

    String cityLower = city.toLowerCase();
    return cityCoordinates[cityLower] ??
        {'latitude': 6.9271, 'longitude': 79.8612, 'state': 'Unknown'};
  }

  /// Get service category from service type
  static String _getServiceCategory(String serviceType) {
    final Map<String, String> categoryMap = {
      'electrical_services': 'Home Services',
      'plumbing': 'Home Services',
      'carpentry': 'Home Services',
      'painting': 'Home Services',
      'ac_repair': 'Appliance Services',
      'roofing': 'Construction',
      'flooring': 'Construction',
    };
    return categoryMap[serviceType] ?? 'General Services';
  }

  /// Get display name for service type
  static String _getServiceDisplayName(String serviceType) {
    return serviceType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
