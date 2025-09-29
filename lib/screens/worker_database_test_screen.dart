// lib/screens/worker_database_test_screen.dart
// Create this temporary screen to test and debug worker database issues

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../constants/service_constants.dart';

class WorkerDatabaseTestScreen extends StatefulWidget {
  @override
  _WorkerDatabaseTestScreenState createState() =>
      _WorkerDatabaseTestScreenState();
}

class _WorkerDatabaseTestScreenState extends State<WorkerDatabaseTestScreen> {
  List<Map<String, dynamic>> _rawWorkerData = [];
  List<WorkerModel> _parsedWorkers = [];
  bool _isLoading = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Database Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testDatabase,
                    child: Text('Test Database'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTestWorker,
                    child: Text('Create Test Worker'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (_testResults.isNotEmpty) ...[
              Text(
                'Test Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResults,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              SizedBox(height: 16),
            ],
            Text(
              'Raw Workers (${_rawWorkerData.length}):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _rawWorkerData.length,
                itemBuilder: (context, index) {
                  var worker = _rawWorkerData[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(worker['workerName'] ?? 'Unknown Worker'),
                      subtitle: Text(
                          'Service: ${worker['serviceType'] ?? 'Unknown'}'),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            worker.toString(),
                            style: TextStyle(
                                fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    StringBuffer results = StringBuffer();

    try {
      results.writeln('=== WORKER DATABASE TEST ===\n');

      // Test 1: Get all workers from database
      QuerySnapshot allWorkers =
          await FirebaseFirestore.instance.collection('workers').get();

      results.writeln(
          'Test 1: Total workers in database: ${allWorkers.docs.length}');

      if (allWorkers.docs.isEmpty) {
        results.writeln('❌ No workers found in database!');
        results.writeln('Solution: Create test workers first\n');
      } else {
        results.writeln('✅ Workers found in database\n');

        // Test 2: Check data structure
        results.writeln('Test 2: Checking data structure...');
        List<Map<String, dynamic>> rawData = [];
        List<WorkerModel> parsedWorkers = [];

        for (var doc in allWorkers.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          rawData.add(data);

          try {
            WorkerModel worker = WorkerModel.fromFirestore(doc);
            parsedWorkers.add(worker);
            results.writeln('✅ Parsed worker: ${worker.workerName}');
          } catch (e) {
            results.writeln('❌ Failed to parse worker ${doc.id}: $e');
            results.writeln('   Data keys: ${data.keys.toList()}');
          }
        }

        setState(() {
          _rawWorkerData = rawData;
          _parsedWorkers = parsedWorkers;
        });

        results.writeln('\nTest 3: Testing search function...');

        // Test 3: Test search with different service types
        List<String> testServiceTypes = [
          'electrical_services',
          'Electrical Services',
          'electrical',
          'ac_repair',
          'plumbing'
        ];

        for (String serviceType in testServiceTypes) {
          try {
            List<WorkerModel> searchResults = await WorkerService.searchWorkers(
              serviceType: serviceType,
              maxDistance: 100.0,
              userLat: 6.9271,
              userLng: 79.8612,
            );
            results.writeln(
                'Search "$serviceType": ${searchResults.length} workers found');

            for (var worker in searchResults) {
              results
                  .writeln('  - ${worker.workerName} (${worker.serviceType})');
            }
          } catch (e) {
            results.writeln('Search "$serviceType": ERROR - $e');
          }
        }
      }
    } catch (e) {
      results.writeln('❌ Database test failed: $e');
    }

    setState(() {
      _isLoading = false;
      _testResults = results.toString();
    });
  }

  Future<void> _createTestWorker() async {
    setState(() => _isLoading = true);

    try {
      // Create a test worker for electrical services
      String workerId = await WorkerService.generateWorkerId();

      WorkerModel testWorker = WorkerModel(
        workerId: workerId,
        workerName: 'Test Electrician',
        firstName: 'Test',
        lastName: 'Electrician',
        serviceType: 'electrical_services', // Match your service type exactly
        serviceCategory: 'electrical_installation', // Match your sub-service
        businessName: 'Test Electrical Services',
        location: WorkerLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          city: 'Colombo',
          state: 'Western',
          postalCode: '00100',
        ),
        experienceYears: 5,
        pricing: WorkerPricing(
          dailyWageLkr: 3000.0,
          halfDayRateLkr: 1500.0,
          minimumChargeLkr: 500.0,
          emergencyRateMultiplier: 1.5,
          overtimeHourlyLkr: 400.0,
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
          vehicleAvailable: true,
          certified: true,
          insurance: true,
          languages: ['English', 'Sinhala'],
        ),
        contact: WorkerContact(
          phoneNumber: '+94771234567',
          whatsappAvailable: true,
          email: 'test@example.com',
        ),
        profile: WorkerProfile(
          bio: 'Test electrical worker for debugging',
          specializations: ['Wiring', 'Electrical Repairs'],
          serviceRadiusKm: 15.0,
        ),
        verified: true, // Make sure this is true for testing
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('workers')
          .doc('test_worker_${DateTime.now().millisecondsSinceEpoch}')
          .set(testWorker.toFirestore());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test worker created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the test
      await _testDatabase();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create test worker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }
}
