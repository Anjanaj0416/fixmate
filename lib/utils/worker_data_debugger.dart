// lib/utils/worker_data_debugger.dart
// NEW FILE - Add this temporarily to debug worker data issues

import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerDataDebugger {
  /// Check and print detailed information about a worker document
  static Future<void> debugWorkerData(String workerId) async {
    print('\n========== WORKER DATA DEBUG ==========');
    print('Worker ID: $workerId');
    print('=' * 40);

    try {
      // Try direct lookup
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (!doc.exists) {
        print('❌ Worker not found by document ID');
        print('Trying to search by worker_id field...');

        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('workers')
            .where('worker_id', isEqualTo: workerId)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          print('❌ Worker not found by worker_id field either');
          print('========== END DEBUG ==========\n');
          return;
        }

        doc = query.docs.first;
        print('✅ Found by worker_id field');
        print('Document ID (UID): ${doc.id}');
      } else {
        print('✅ Found by document ID');
      }

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        print('❌ Document data is null');
        print('========== END DEBUG ==========\n');
        return;
      }

      print('\n📋 DOCUMENT STRUCTURE:');
      print('-' * 40);

      // Check each required field
      _checkField(data, 'worker_id');
      _checkField(data, 'worker_name');
      _checkField(data, 'first_name');
      _checkField(data, 'last_name');
      _checkField(data, 'service_type');
      _checkField(data, 'service_category');
      _checkField(data, 'business_name');
      _checkField(data, 'rating');
      _checkField(data, 'experience_years');
      _checkField(data, 'jobs_completed');
      _checkField(data, 'success_rate');
      _checkField(data, 'verified');
      _checkField(data, 'profile_picture_url');

      print('\n📦 NESTED OBJECTS:');
      print('-' * 40);

      // Check nested objects
      _checkNestedObject(data, 'location',
          ['latitude', 'longitude', 'city', 'state', 'postal_code']);

      _checkNestedObject(data, 'contact',
          ['phone_number', 'email', 'whatsapp_available', 'website']);

      _checkNestedObject(data, 'pricing', [
        'daily_wage_lkr',
        'half_day_rate_lkr',
        'minimum_charge_lkr',
        'overtime_hourly_lkr',
        'emergency_rate_multiplier'
      ]);

      _checkNestedObject(data, 'availability',
          ['available_today', 'available_this_week', 'working_hours']);

      _checkNestedObject(data, 'profile', ['bio', 'specializations']);

      print('\n✅ DEBUG COMPLETE');
      print('========== END DEBUG ==========\n');
    } catch (e) {
      print('❌ ERROR during debug: $e');
      print('========== END DEBUG ==========\n');
    }
  }

  static void _checkField(Map<String, dynamic> data, String fieldName) {
    if (data.containsKey(fieldName)) {
      var value = data[fieldName];
      String type = value.runtimeType.toString();

      if (value is Map) {
        print('⚠️  $fieldName: [Map] - Should be primitive type!');
        print(
            '    Data: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}...');
      } else {
        print('✅ $fieldName: [$type] = $value');
      }
    } else {
      print('❌ $fieldName: MISSING');
    }
  }

  static void _checkNestedObject(Map<String, dynamic> data, String objectName,
      List<String> expectedFields) {
    print('\n  📂 $objectName:');

    if (!data.containsKey(objectName)) {
      print('    ❌ MISSING');
      return;
    }

    var obj = data[objectName];

    if (obj == null) {
      print('    ❌ NULL');
      return;
    }

    if (obj is! Map) {
      print('    ❌ Not a Map, is ${obj.runtimeType}');
      return;
    }

    Map<String, dynamic> objMap = obj as Map<String, dynamic>;

    for (String field in expectedFields) {
      if (objMap.containsKey(field)) {
        var value = objMap[field];
        String type = value.runtimeType.toString();

        if (field == 'working_hours' && value is Map) {
          print('    ✅ $field: [Map]');
          Map workingHours = value as Map;
          print('       - start: ${workingHours['start']}');
          print('       - end: ${workingHours['end']}');
        } else if (field == 'specializations' && value is List) {
          print('    ✅ $field: [List] (${value.length} items)');
        } else {
          String displayValue = value.toString();
          if (displayValue.length > 50) {
            displayValue = displayValue.substring(0, 50) + '...';
          }
          print('    ✅ $field: [$type] = $displayValue');
        }
      } else {
        print('    ❌ $field: MISSING');
      }
    }
  }

  /// Run a full database scan to check all workers
  static Future<void> scanAllWorkers() async {
    print('\n========== SCANNING ALL WORKERS ==========');

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('workers').get();

      print('Total workers found: ${snapshot.docs.length}\n');

      int validWorkers = 0;
      int invalidWorkers = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data == null) {
          print('❌ Worker ${doc.id}: NULL DATA');
          invalidWorkers++;
          continue;
        }

        // Check required fields
        bool isValid = true;
        List<String> missingFields = [];

        List<String> requiredFields = [
          'worker_id',
          'worker_name',
          'service_type',
          'location',
          'contact',
          'pricing'
        ];

        for (String field in requiredFields) {
          if (!data.containsKey(field) || data[field] == null) {
            missingFields.add(field);
            isValid = false;
          }
        }

        if (isValid) {
          validWorkers++;
          print('✅ Worker ${doc.id}: ${data['worker_name']} - VALID');
        } else {
          invalidWorkers++;
          print(
              '⚠️  Worker ${doc.id}: ${data['worker_name'] ?? 'Unknown'} - MISSING: ${missingFields.join(', ')}');
        }
      }

      print('\n📊 SUMMARY:');
      print('  ✅ Valid: $validWorkers');
      print('  ⚠️  Invalid: $invalidWorkers');
      print('========== END SCAN ==========\n');
    } catch (e) {
      print('❌ ERROR during scan: $e');
      print('========== END SCAN ==========\n');
    }
  }
}
