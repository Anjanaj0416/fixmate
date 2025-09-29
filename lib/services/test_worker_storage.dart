import 'package:flutter/material.dart';
import '../services/worker_storage_service.dart';
import '../services/ml_service.dart';

class TestWorkerStorage extends StatelessWidget {
  Future<void> testEmailExtraction() async {
    // Create sample ML worker
    MLWorker testWorker = MLWorker(
      workerId: 'HM_0001',
      workerName: 'Test Worker',
      serviceType: 'electrical_services',
      rating: 4.5,
      experienceYears: 5,
      dailyWageLkr: 5000,
      phoneNumber: '+94771234567',
      email: 'test.worker@fixmate.worker', // ✅ Actual email
      city: 'colombo',
      distanceKm: 5.0,
      aiConfidence: 0.95,
      bio: 'Expert electrician',
    );

    print('📧 Testing email extraction...');

    // Test: Check if worker exists by email
    bool exists =
        await WorkerStorageService.checkWorkerExistsByEmail(testWorker.email);
    print('Worker exists: $exists');

    // Test: Store worker
    if (!exists) {
      String uid =
          await WorkerStorageService.storeWorkerFromML(mlWorker: testWorker);
      print('✅ Worker stored with UID: $uid');
    } else {
      print('⚠️  Worker already exists');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: testEmailExtraction,
      child: Text('Test Worker Storage'),
    );
  }
}
