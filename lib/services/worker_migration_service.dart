import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate existing workers to new format
  static Future<void> migrateExistingWorkers() async {
    print('🔄 Starting worker migration...');

    // Get all existing workers
    QuerySnapshot workersSnapshot =
        await _firestore.collection('workers').get();

    int migrated = 0;
    int errors = 0;

    for (var doc in workersSnapshot.docs) {
      try {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if already migrated
        if (data['worker_id'] != null &&
            data['worker_id'].toString().startsWith('HM_')) {
          // Check format: should be HM_XXXX (7 chars)
          if (data['worker_id'].toString().length == 7) {
            print('✅ Worker ${doc.id} already migrated');
            continue;
          }
        }

        // Generate new formatted ID
        String newWorkerId = await _generateNextWorkerId();

        // Update worker document
        await doc.reference.update({
          'worker_id': newWorkerId,
          'migrated_at': FieldValue.serverTimestamp(),
        });

        // Update user document
        await _firestore.collection('users').doc(doc.id).update({
          'workerId': newWorkerId,
        });

        migrated++;
        print('✅ Migrated worker ${doc.id} to $newWorkerId');
      } catch (e) {
        errors++;
        print('❌ Error migrating worker ${doc.id}: $e');
      }
    }

    print('🎉 Migration complete!');
    print('   Migrated: $migrated');
    print('   Errors: $errors');
  }

  static Future<String> _generateNextWorkerId() async {
    QuerySnapshot workersSnapshot = await _firestore
        .collection('workers')
        .where('worker_id', isGreaterThanOrEqualTo: 'HM_')
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

    return 'HM_${nextNumber.toString().padLeft(4, '0')}';
  }
}
