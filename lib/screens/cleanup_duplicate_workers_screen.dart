// lib/screens/cleanup_duplicate_workers_screen.dart
// Run this ONCE to fix duplicate worker entries in your database

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CleanupDuplicateWorkersScreen extends StatefulWidget {
  @override
  _CleanupDuplicateWorkersScreenState createState() =>
      _CleanupDuplicateWorkersScreenState();
}

class _CleanupDuplicateWorkersScreenState
    extends State<CleanupDuplicateWorkersScreen> {
  final ScrollController _scrollController = ScrollController();
  String _log = '';
  bool _isRunning = false;
  bool _isDryRun = true; // Set to false to actually fix data

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _cleanupDuplicates() async {
    setState(() {
      _log = '';
      _isRunning = true;
    });

    try {
      _addLog('========================================');
      _addLog('DUPLICATE WORKER CLEANUP TOOL');
      _addLog(_isDryRun
          ? '🔍 DRY RUN MODE (No changes will be made)'
          : '⚠️ LIVE MODE (Will fix data)');
      _addLog('========================================\n');

      // Step 1: Find all workers
      _addLog('📊 Step 1: Fetching all workers from database...');
      QuerySnapshot allWorkers =
          await FirebaseFirestore.instance.collection('workers').get();
      _addLog('   Found ${allWorkers.docs.length} worker documents\n');

      // Step 2: Group workers by email and phone
      _addLog('🔍 Step 2: Analyzing for duplicates...');
      Map<String, List<DocumentSnapshot>> workersByEmail = {};
      Map<String, List<DocumentSnapshot>> workersByPhone = {};

      for (var doc in allWorkers.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String email = data['email'] ?? '';
        String phone = data['phone_number'] ?? '';

        if (email.isNotEmpty) {
          workersByEmail.putIfAbsent(email, () => []);
          workersByEmail[email]!.add(doc);
        }

        if (phone.isNotEmpty) {
          workersByPhone.putIfAbsent(phone, () => []);
          workersByPhone[phone]!.add(doc);
        }
      }

      // Step 3: Find duplicates
      List<String> duplicateEmails = workersByEmail.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => entry.key)
          .toList();

      List<String> duplicatePhones = workersByPhone.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => entry.key)
          .toList();

      _addLog('   Duplicate emails found: ${duplicateEmails.length}');
      _addLog('   Duplicate phones found: ${duplicatePhones.length}\n');

      if (duplicateEmails.isEmpty && duplicatePhones.isEmpty) {
        _addLog('✅ No duplicates found! Your database is clean.');
        setState(() => _isRunning = false);
        return;
      }

      // Step 4: Fix duplicates by email
      _addLog('🔧 Step 3: Processing duplicate emails...\n');
      int fixedByEmail = 0;

      for (String email in duplicateEmails) {
        List<DocumentSnapshot> duplicates = workersByEmail[email]!;
        _addLog('📧 Found ${duplicates.length} workers with email: $email');

        // Sort by created_at to keep the oldest one
        duplicates.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          Timestamp? aTime = aData['created_at'] as Timestamp?;
          Timestamp? bTime = bData['created_at'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return aTime.compareTo(bTime);
        });

        // Keep the first (oldest) one
        DocumentSnapshot keepDoc = duplicates.first;
        var keepData = keepDoc.data() as Map<String, dynamic>;
        String keepWorkerId = keepData['worker_id'] ?? 'UNKNOWN';

        _addLog('   ✅ Keeping: ${keepDoc.id} (worker_id: $keepWorkerId)');

        // Remove or update duplicates
        for (int i = 1; i < duplicates.length; i++) {
          DocumentSnapshot dupDoc = duplicates[i];
          var dupData = dupDoc.data() as Map<String, dynamic>;
          String dupWorkerId = dupData['worker_id'] ?? 'UNKNOWN';

          _addLog('   ❌ Duplicate: ${dupDoc.id} (worker_id: $dupWorkerId)');

          if (!_isDryRun) {
            // Update all references to this worker_id
            await _updateWorkerReferences(dupWorkerId, keepWorkerId);

            // Delete the duplicate worker document
            await FirebaseFirestore.instance
                .collection('workers')
                .doc(dupDoc.id)
                .delete();

            _addLog('      🗑️ Deleted duplicate and updated references');
          } else {
            _addLog('      [DRY RUN] Would delete and update references');
          }

          fixedByEmail++;
        }
        _addLog('');
      }

      // Step 5: Fix duplicates by phone
      _addLog('🔧 Step 4: Processing duplicate phones...\n');
      int fixedByPhone = 0;

      for (String phone in duplicatePhones) {
        List<DocumentSnapshot> duplicates = workersByPhone[phone]!;

        // Skip if already processed by email
        var firstData = duplicates.first.data() as Map<String, dynamic>;
        String firstEmail = firstData['email'] ?? '';
        if (duplicateEmails.contains(firstEmail)) {
          continue;
        }

        _addLog('📱 Found ${duplicates.length} workers with phone: $phone');

        // Keep the oldest one
        duplicates.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          Timestamp? aTime = aData['created_at'] as Timestamp?;
          Timestamp? bTime = bData['created_at'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return aTime.compareTo(bTime);
        });

        DocumentSnapshot keepDoc = duplicates.first;
        var keepData = keepDoc.data() as Map<String, dynamic>;
        String keepWorkerId = keepData['worker_id'] ?? 'UNKNOWN';

        _addLog('   ✅ Keeping: ${keepDoc.id} (worker_id: $keepWorkerId)');

        for (int i = 1; i < duplicates.length; i++) {
          DocumentSnapshot dupDoc = duplicates[i];
          var dupData = dupDoc.data() as Map<String, dynamic>;
          String dupWorkerId = dupData['worker_id'] ?? 'UNKNOWN';

          _addLog('   ❌ Duplicate: ${dupDoc.id} (worker_id: $dupWorkerId)');

          if (!_isDryRun) {
            await _updateWorkerReferences(dupWorkerId, keepWorkerId);
            await FirebaseFirestore.instance
                .collection('workers')
                .doc(dupDoc.id)
                .delete();
            _addLog('      🗑️ Deleted duplicate and updated references');
          } else {
            _addLog('      [DRY RUN] Would delete and update references');
          }

          fixedByPhone++;
        }
        _addLog('');
      }

      // Summary
      _addLog('========================================');
      _addLog('CLEANUP SUMMARY');
      _addLog('========================================');
      _addLog('Total duplicates found: ${fixedByEmail + fixedByPhone}');
      _addLog('Fixed by email: $fixedByEmail');
      _addLog('Fixed by phone: $fixedByPhone');

      if (_isDryRun) {
        _addLog('\n⚠️ This was a DRY RUN - no changes were made');
        _addLog('Set _isDryRun = false and run again to fix the data');
      } else {
        _addLog('\n✅ Cleanup completed successfully!');
      }
    } catch (e) {
      _addLog('\n❌ ERROR: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  /// Update all references to old worker_id with new worker_id
  Future<void> _updateWorkerReferences(
      String oldWorkerId, String newWorkerId) async {
    _addLog('      🔄 Updating references from $oldWorkerId to $newWorkerId');

    // Update bookings
    QuerySnapshot bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('worker_id', isEqualTo: oldWorkerId)
        .get();

    for (var doc in bookings.docs) {
      await doc.reference.update({'worker_id': newWorkerId});
    }
    if (bookings.docs.isNotEmpty) {
      _addLog('         Updated ${bookings.docs.length} bookings');
    }

    // Update chat_rooms
    QuerySnapshot chats = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('worker_id', isEqualTo: oldWorkerId)
        .get();

    for (var doc in chats.docs) {
      await doc.reference.update({'worker_id': newWorkerId});
    }
    if (chats.docs.isNotEmpty) {
      _addLog('         Updated ${chats.docs.length} chat rooms');
    }

    // Update any other collections that reference worker_id
    // Add more collections here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cleanup Duplicate Workers'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Warning banner
          Container(
            color: _isDryRun ? Colors.blue[100] : Colors.red[100],
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _isDryRun ? Icons.info : Icons.warning,
                  color: _isDryRun ? Colors.blue[900] : Colors.red[900],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isDryRun
                        ? 'DRY RUN MODE: This will only analyze your data, not change it'
                        : '⚠️ LIVE MODE: This will permanently modify your database!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isDryRun ? Colors.blue[900] : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Run in DRY RUN mode first to see what would be fixed\n'
                      '2. Review the results carefully\n'
                      '3. If everything looks good, set _isDryRun = false in code\n'
                      '4. Run again to actually fix the duplicates',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _cleanupDuplicates,
              icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.play_arrow),
              label: Text(
                _isRunning
                    ? 'Running...'
                    : (_isDryRun ? 'Run Dry Run Analysis' : 'Fix Duplicates'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDryRun ? Colors.blue : Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Log output
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  _log.isEmpty ? 'Press the button to start...' : _log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.green[300],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
