import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/customer_model.dart';
import 'dart:math' as math;
import '../services/id_generator_service.dart';

class WorkerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique worker ID
  static Future<String> generateWorkerId() async {
    return await IDGeneratorService.generateWorkerId();
  }

  static Future<WorkerModel?> getWorkerByEmail(String email) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      String uid = query.docs.first.id;
      DocumentSnapshot workerDoc =
          await FirebaseFirestore.instance.collection('workers').doc(uid).get();

      if (workerDoc.exists) {
        return WorkerModel.fromFirestore(workerDoc);
      }
      return null;
    } catch (e) {
      print('Error fetching worker by email: $e');
      return null;
    }
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

  // Get worker by ID
  static Future<WorkerModel?> getWorkerById(String workerId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return WorkerModel.fromFirestore(query.docs.first);
    } catch (e) {
      print('Error fetching worker by ID: $e');
      return null;
    }
  }

  // Get worker by user UID
  static Future<WorkerModel?> getWorkerByUid(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('workers').doc(uid).get();

      if (doc.exists) {
        return WorkerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching worker by UID: $e');
      return null;
    }
  }

  // Update worker profile
  static Future<void> updateWorker(
      String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('workers').doc(uid).update(updates);
    } catch (e) {
      print('Error updating worker: $e');
      rethrow;
    }
  }

  // Calculate distance between two coordinates
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // Search workers
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

      // Filter by service type - use the correct field name from WorkerModel
      query = query.where('serviceType', isEqualTo: serviceType);

      // Filter by city if provided
      if (city != null && city.isNotEmpty) {
        query = query.where('location.city', isEqualTo: city);
      }

      // Filter by service category if provided
      if (serviceCategory != null && serviceCategory.isNotEmpty) {
        query = query.where('serviceCategory', isEqualTo: serviceCategory);
      }

      // Remove the strict verification filter temporarily for testing
      // Comment out these lines to see all workers first:
      // query = query.where('availability.availableToday', isEqualTo: true);
      // query = query.where('verified', isEqualTo: true);

      print('DEBUG: Executing query...');
      QuerySnapshot querySnapshot = await query.get();
      print('DEBUG: Found ${querySnapshot.docs.length} workers');

      if (querySnapshot.docs.isEmpty) {
        // Try a broader search without filters to see if there are any workers at all
        print('DEBUG: No workers found with filters, trying broader search...');
        QuerySnapshot allWorkers = await _firestore.collection('workers').get();
        print('DEBUG: Total workers in database: ${allWorkers.docs.length}');

        // Print first worker's data for debugging
        if (allWorkers.docs.isNotEmpty) {
          print('DEBUG: Sample worker data: ${allWorkers.docs.first.data()}');
        }
      }

      List<WorkerModel> workers = [];

      for (var doc in querySnapshot.docs) {
        try {
          WorkerModel worker = WorkerModel.fromFirestore(doc);
          workers.add(worker);
          print('DEBUG: Successfully parsed worker: ${worker.workerName}');
        } catch (e) {
          print('DEBUG: Error parsing worker ${doc.id}: $e');
          print('DEBUG: Worker data: ${doc.data()}');
        }
      }

      // Filter by specialization if provided
      if (specialization != null && specialization.isNotEmpty) {
        workers = workers
            .where((worker) =>
                worker.profile.specializations.contains(specialization))
            .toList();
      }

      // Filter by distance if location is provided
      if (maxDistance != null && userLat != null && userLng != null) {
        workers = workers.where((worker) {
          double distance = _calculateDistance(userLat, userLng,
              worker.location.latitude, worker.location.longitude);
          return distance <= maxDistance;
        }).toList();
      }

      print('DEBUG: Returning ${workers.length} workers after all filters');
      return workers;
    } catch (e) {
      print('DEBUG: Error in searchWorkers: $e');
      throw Exception('Failed to search workers: ${e.toString()}');
    }
  }

  // Calculate distance between two points
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Add the missing method that was being called
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

      // Filter by distance
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
}

class CustomerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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

class ServiceTypes {
  static const Map<String, Map<String, dynamic>> _serviceTypes = {
    'ac_repair': {
      'name': 'AC Repair',
      'categories': 'AC Repair',
      'specializations': [
        'Window units',
        'Central AC',
        'Split systems',
        'Maintenance',
        'Installation'
      ]
    },
    'appliance_repair': {
      'name': 'Appliance Repair',
      'categories': 'Appliance Repair',
      'specializations': [
        'Refrigerator',
        'Dishwasher',
        'Microwave',
        'Washing machine',
        'Oven & stove',
        'Dryer',
        'Emergency service'
      ]
    },
    'carpentry': {
      'name': 'Carpentry',
      'categories': 'Carpentry',
      'specializations': [
        'Custom furniture',
        'Restoration',
        'Repairs',
        'Decorative',
        'Cabinet making',
        'Wooden flooring'
      ]
    },
    'cleaning': {
      'name': 'Cleaning',
      'categories': 'Cleaning',
      'specializations': [
        'Deep cleaning',
        'Post-construction',
        'Regular maintenance',
        'Carpet cleaning',
        'Upholstery cleaning'
      ]
    },
    'electrical': {
      'name': 'Electrical',
      'categories': 'Electrical',
      'specializations': [
        'Installation',
        'Wiring',
        'Safety inspection',
        'Emergency service',
        'Lighting systems',
        'Solar panel setup',
        'Maintenance'
      ]
    },
    'gardening': {
      'name': 'Gardening',
      'categories': 'Gardening',
      'specializations': [
        'Landscaping',
        'Lawn care',
        'Tree trimming',
        'Irrigation systems'
      ]
    },
    'general_maintenance': {
      'name': 'General Maintenance',
      'categories': 'General Maintenance',
      'specializations': [
        'Property upkeep',
        'Preventive maintenance',
        'Multiple repairs',
        'Furniture assembly',
        'Small fixture replacements'
      ]
    },
    'masonry': {
      'name': 'Masonry',
      'categories': 'Masonry',
      'specializations': [
        'Stone work',
        'Brick work',
        'Concrete',
        'Tile setting',
        'Wall finishing'
      ]
    },
    'painting': {
      'name': 'Painting',
      'categories': 'Painting',
      'specializations': [
        'Interior',
        'Exterior',
        'Commercial',
        'Decorative',
        'Waterproofing',
        'Wall textures'
      ]
    },
    'plumbing': {
      'name': 'Plumbing',
      'categories': 'Plumbing',
      'specializations': [
        'Installation',
        'Water heater service',
        'Emergency repairs',
        'Maintenance',
        'Drain cleaning',
        'Pipe replacement',
        'Bathroom fittings'
      ]
    },
    'roofing': {
      'name': 'Roofing',
      'categories': 'Roofing',
      'specializations': [
        'Roof installation',
        'Leak repair',
        'Tile replacement',
        'Waterproofing',
        'Gutter maintenance'
      ]
    }
  };

  static List<Map<String, dynamic>> get serviceTypesList {
    return _serviceTypes.entries
        .map((entry) => {
              'key': entry.key,
              'name': entry.value['name'],
              'categories': entry.value['categories'],
              'specializations': entry.value['specializations']
            })
        .toList();
  }

  static String getServiceName(String serviceKey) {
    return _serviceTypes[serviceKey]?['name'] ?? 'Unknown Service';
  }

  static List<String> getSpecializations(String? serviceKey) {
    if (serviceKey == null || serviceKey.isEmpty) return [];
    return List<String>.from(
        _serviceTypes[serviceKey]?['specializations'] ?? []);
  }

  // Updated to return single category string instead of list
  static String getCategory(String? serviceKey) {
    if (serviceKey == null || serviceKey.isEmpty) return '';
    return _serviceTypes[serviceKey]?['categories'] ?? '';
  }

  // Deprecated - use getCategory instead
  @Deprecated('Use getCategory instead')
  static List<String> getCategories(String? serviceKey) {
    String category = getCategory(serviceKey);
    return category.isNotEmpty ? [category] : [];
  }

  // Add helper method to check if service exists
  static bool hasService(String serviceKey) {
    return _serviceTypes.containsKey(serviceKey);
  }

  // Get all service keys
  static List<String> get allServiceKeys {
    return _serviceTypes.keys.toList();
  }
}

class Languages {
  static const List<String> supportedLanguages = [
    'Sinhala',
    'Tamil',
    'English',
  ];
}

class Cities {
  static const List<String> sriLankanCities = [
    'Colombo',
    'Colombo 01 (Fort)',
    'Colombo 02 (Slave Island)',
    'Colombo 03 (Kollupitiya)',
    'Colombo 04 (Bambalapitiya)',
    'Colombo 05 (Narahenpita)',
    'Colombo 06 (Wellawatta)',
    'Colombo 07 (Cinnamon Gardens)',
    'Colombo 08 (Borella)',
    'Colombo 09 (Dematagoda)',
    'Colombo 10 (Maradana)',
    'Colombo 11 (Pettah)',
    'Colombo 12 (Hulftsdorp)',
    'Colombo 13 (Kotahena)',
    'Colombo 14 (Grandpass)',
    'Colombo 15 (Mutwal)',
    'Dehiwala-Mount Lavinia',
    'Mount Lavinia',
    'Dehiwala',
    'Moratuwa',
    'Sri Jayawardenepura Kotte',
    'Battaramulla',
    'Maharagama',
    'Kesbewa',
    'Piliyandala',
    'Nugegoda',
    'Homagama',
    'Padukka',
    'Hanwella',
    'Avissawella',
    'Seethawaka',
    'Gampaha',
    'Negombo',
    'Katunayake',
    'Seeduwa',
    'Liyanagemulla',
    'Wattala',
    'Kelaniya',
    'Peliyagoda',
    'Kandana',
    'Ja-Ela',
    'Ekala',
    'Gampaha',
    'Veyangoda',
    'Ganemulla',
    'Kadawatha',
    'Ragama',
    'Kiribathgoda',
    'Kelaniya',
    'Kalutara',
    'Panadura',
    'Horana',
    'Matugama',
    'Agalawatta',
    'Bandaragama',
    'Ingiriya',
    'Bulathsinhala',
    'Mathugama',
    'Kalutara',
    'Beruwala',
    'Aluthgama',
    'Bentota',
    'Ambalangoda',
    'Hikkaduwa',
    'Galle',
    'Unawatuna',
    'Koggala',
    'Habaraduwa',
    'Ahangama',
    'Midigama',
    'Weligama',
    'Mirissa',
    'Matara',
    'Dondra',
    'Dickwella',
    'Tangalle',
    'Hambantota',
    'Tissamaharama',
    'Kataragama',
    'Monaragala',
    'Wellawaya',
    'Buttala',
    'Badulla',
    'Bandarawela',
    'Ella',
    'Haputale',
    'Diyatalawa',
    'Welimada',
    'Mahiyanganaya',
    'Ampara',
    'Kalmunai',
    'Sammanthurai',
    'Akkaraipattu',
    'Pottuvil',
    'Batticaloa',
    'Eravur',
    'Valaichchenai',
    'Kattankudy',
    'Trincomalee',
    'Kinniya',
    'Mutur',
    'Kantale',
    'Polonnaruwa',
    'Kaduruwela',
    'Medirigiriya',
    'Hingurakgoda',
    'Anuradhapura',
    'Kekirawa',
    'Thambuttegama',
    'Eppawala',
    'Medawachchiya',
    'Kurunegala',
    'Puttalam',
    'Chilaw',
    'Wennappuwa',
    'Marawila',
    'Nattandiya',
    'Dankotuwa',
    'Kuliyapitiya',
    'Nikaweratiya',
    'Bingiriya',
    'Wariyapola',
    'Pannala',
    'Matale',
    'Dambulla',
    'Sigiriya',
    'Naula',
    'Ukuwela',
    'Rattota',
    'Kandy',
    'Peradeniya',
    'Gampola',
    'Nawalapitiya',
    'Hatton',
    'Nuwara Eliya',
    'Talawakelle',
    'Nanu Oya',
    'Ragala',
    'Kegalle',
    'Mawanella',
    'Warakapola',
    'Rambukkana',
    'Kitulgala',
    'Ruwanwella',
    'Deraniyagala',
    'Ratnapura',
    'Embilipitiya',
    'Balangoda',
    'Rakwana',
    'Pelmadulla',
    'Kahawatta',
    'Kuruwita',
    'Eheliyagoda',
    'Jaffna',
    'Chavakacheri',
    'Valvettithurai',
    'Point Pedro',
    'Karainagar',
    'Vavuniya',
    'Mannar',
    'Kilinochchi',
    'Mullativu',
  ];
}
