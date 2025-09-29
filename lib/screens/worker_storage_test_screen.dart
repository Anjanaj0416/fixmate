// lib/screens/worker_storage_test_screen.dart
// Add this screen to test the new worker storage functionality

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/worker_storage_service.dart';
import '../services/ml_service.dart';
import '../models/worker_model.dart';

class WorkerStorageTestScreen extends StatefulWidget {
  @override
  _WorkerStorageTestScreenState createState() =>
      _WorkerStorageTestScreenState();
}

class _WorkerStorageTestScreenState extends State<WorkerStorageTestScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Storage Tests'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test 1: Generate Formatted ID
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test 1: Generate Formatted Worker ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGenerateId,
                      child: Text('Generate New ID'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Test 2: Check Worker by Email
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test 2: Check Worker Exists by Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Worker Email',
                        hintText: 'test.worker@fixmate.worker',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testCheckEmail,
                      child: Text('Check If Exists'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Test 3: Create Sample Worker
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test 3: Create Sample Worker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testCreateWorker,
                      child: Text('Create Test Worker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Test 4: View All Workers
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test 4: View All Workers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testViewWorkers,
                      child: Text('View All Workers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Test 5: Verify Database Structure
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test 5: Verify Database Structure',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testStructure,
                      child: Text('Verify Structure'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Results Display
            if (_testResults.isNotEmpty)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Test Results',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _testResults = '';
                              });
                            },
                          ),
                        ],
                      ),
                      Divider(),
                      Container(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGenerateId() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      StringBuffer results = StringBuffer();
      results.writeln('=== TEST 1: GENERATE FORMATTED ID ===\n');

      // Generate 5 IDs to test sequential ordering
      for (int i = 0; i < 5; i++) {
        String workerId =
            await WorkerStorageService.generateFormattedWorkerId();
        results.writeln('Generated ID ${i + 1}: $workerId');

        // Verify format
        if (workerId.startsWith('HM_') && workerId.length == 7) {
          results.writeln('  ✅ Format correct (HM_XXXX)');
        } else {
          results.writeln('  ❌ Format incorrect!');
        }
        results.writeln('');
      }

      results.writeln('✅ Test completed successfully!');

      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCheckEmail() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      StringBuffer results = StringBuffer();
      results.writeln('=== TEST 2: CHECK WORKER BY EMAIL ===\n');
      results.writeln('Email: $email\n');

      bool exists = await WorkerStorageService.checkWorkerExistsByEmail(email);

      if (exists) {
        results.writeln('✅ Worker EXISTS in database');

        String? uid = await WorkerStorageService.getWorkerUidByEmail(email);
        if (uid != null) {
          results.writeln('Worker UID: $uid');

          // Get worker details
          DocumentSnapshot workerDoc = await FirebaseFirestore.instance
              .collection('workers')
              .doc(uid)
              .get();

          if (workerDoc.exists) {
            Map<String, dynamic> data =
                workerDoc.data() as Map<String, dynamic>;
            results.writeln('\nWorker Details:');
            results.writeln('  Worker ID: ${data['worker_id']}');
            results.writeln('  Name: ${data['worker_name']}');
            results.writeln('  Service: ${data['service_type']}');
            results.writeln('  City: ${data['location']['city']}');
          }
        }
      } else {
        results.writeln('❌ Worker DOES NOT EXIST in database');
      }

      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateWorker() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      StringBuffer results = StringBuffer();
      results.writeln('=== TEST 3: CREATE SAMPLE WORKER ===\n');

      // Create sample MLWorker
      MLWorker sampleWorker = MLWorker(
        workerId: 'TEST_001',
        workerName: 'Test Worker ${DateTime.now().millisecondsSinceEpoch}',
        serviceType: 'electrical_services',
        rating: 4.5,
        experienceYears: 5,
        dailyWageLkr: 5000,
        phoneNumber: '+94771234567',
        email:
            'test.worker${DateTime.now().millisecondsSinceEpoch}@fixmate.worker',
        city: 'colombo',
        distanceKm: 5.0,
        aiConfidence: 0.95,
        bio: 'Expert electrician with 5 years experience',
      );

      results.writeln('Creating worker:');
      results.writeln('  Name: ${sampleWorker.workerName}');
      results.writeln('  Email: ${sampleWorker.email}');
      results.writeln('  Phone: ${sampleWorker.phoneNumber}\n');

      String uid = await WorkerStorageService.storeWorkerFromML(
        mlWorker: sampleWorker,
      );

      results.writeln('✅ Worker created successfully!');
      results.writeln('Firebase UID: $uid\n');

      // Verify in database
      DocumentSnapshot workerDoc =
          await FirebaseFirestore.instance.collection('workers').doc(uid).get();

      if (workerDoc.exists) {
        Map<String, dynamic> data = workerDoc.data() as Map<String, dynamic>;
        results.writeln('Verification:');
        results.writeln('  ✅ Worker document exists');
        results.writeln('  Worker ID: ${data['worker_id']}');
        results.writeln('  Email: ${data['contact']['email']}');
        results.writeln('  Service Type: ${data['service_type']}');
      }

      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testViewWorkers() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      StringBuffer results = StringBuffer();
      results.writeln('=== TEST 4: VIEW ALL WORKERS ===\n');

      QuerySnapshot workersSnapshot =
          await FirebaseFirestore.instance.collection('workers').get();

      results.writeln('Total workers: ${workersSnapshot.docs.length}\n');

      if (workersSnapshot.docs.isEmpty) {
        results.writeln('❌ No workers found in database');
      } else {
        int count = 0;
        for (var doc in workersSnapshot.docs) {
          count++;
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          results.writeln('Worker #$count:');
          results.writeln('  UID: ${doc.id}');
          results.writeln('  Worker ID: ${data['worker_id']}');
          results.writeln('  Name: ${data['worker_name']}');
          results.writeln('  Email: ${data['contact']['email']}');
          results.writeln('  Service: ${data['service_type']}');
          results.writeln('  City: ${data['location']['city']}');
          results.writeln('');

          if (count >= 10) {
            results.writeln('... and ${workersSnapshot.docs.length - 10} more');
            break;
          }
        }
      }

      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStructure() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      StringBuffer results = StringBuffer();
      results.writeln('=== TEST 5: VERIFY DATABASE STRUCTURE ===\n');

      QuerySnapshot workersSnapshot =
          await FirebaseFirestore.instance.collection('workers').limit(1).get();

      if (workersSnapshot.docs.isEmpty) {
        results.writeln('❌ No workers to verify. Create a worker first.');
      } else {
        DocumentSnapshot doc = workersSnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        results.writeln('Verifying worker structure...\n');

        // Required fields check
        List<String> requiredFields = [
          'worker_id',
          'worker_name',
          'first_name',
          'last_name',
          'service_type',
          'service_category',
          'business_name',
          'location',
          'rating',
          'experience_years',
          'pricing',
          'availability',
          'capabilities',
          'contact',
          'profile',
        ];

        for (String field in requiredFields) {
          if (data.containsKey(field)) {
            results.writeln('✅ $field: exists');
          } else {
            results.writeln('❌ $field: MISSING!');
          }
        }

        results.writeln('\nNested Structure Check:');

        // Check contact
        if (data['contact'] != null) {
          Map<String, dynamic> contact = data['contact'];
          results.writeln('📧 Contact:');
          results.writeln('   Email: ${contact['email']}');
          results.writeln('   Phone: ${contact['phone_number']}');
        }

        // Check location
        if (data['location'] != null) {
          Map<String, dynamic> location = data['location'];
          results.writeln('📍 Location:');
          results.writeln('   City: ${location['city']}');
          results.writeln(
              '   Coordinates: (${location['latitude']}, ${location['longitude']})');
        }

        // Check pricing
        if (data['pricing'] != null) {
          Map<String, dynamic> pricing = data['pricing'];
          results.writeln('💰 Pricing:');
          results.writeln('   Daily Wage: LKR ${pricing['daily_wage_lkr']}');
          results.writeln('   Half Day: LKR ${pricing['half_day_rate_lkr']}');
        }

        results.writeln('\n✅ Structure verification complete!');
      }

      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
