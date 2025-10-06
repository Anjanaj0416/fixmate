// lib/screens/verify_worker_ids_screen.dart
// Use this to verify that worker_ids are consistent after the fix

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyWorkerIdsScreen extends StatefulWidget {
  @override
  _VerifyWorkerIdsScreenState createState() => _VerifyWorkerIdsScreenState();
}

class _VerifyWorkerIdsScreenState extends State<VerifyWorkerIdsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _log = '';
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _verifyWorkerIds() async {
    setState(() {
      _log = '';
      _isRunning = true;
    });

    try {
      _addLog('========================================');
      _addLog('WORKER ID VERIFICATION TOOL');
      _addLog('========================================\n');

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('❌ No user logged in');
        setState(() => _isRunning = false);
        return;
      }

      _addLog('👤 Current User:');
      _addLog('   Firebase UID: ${user.uid}');
      _addLog('   Email: ${user.email}\n');

      // Check if user is a worker
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      String? myWorkerId;
      String? myWorkerName;

      if (workerDoc.exists) {
        var data = workerDoc.data() as Map<String, dynamic>;
        myWorkerId = data['worker_id'];
        myWorkerName = data['worker_name'];
        _addLog('✅ You are a worker:');
        _addLog('   Worker ID: $myWorkerId');
        _addLog('   Name: $myWorkerName\n');
      } else {
        _addLog('ℹ️ You are not a worker (likely a customer)\n');
      }

      // Check all bookings
      _addLog('📋 CHECKING BOOKINGS...\n');
      QuerySnapshot allBookings =
          await FirebaseFirestore.instance.collection('bookings').get();

      _addLog('Total bookings in database: ${allBookings.docs.length}\n');

      if (myWorkerId != null) {
        QuerySnapshot myBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('worker_id', isEqualTo: myWorkerId)
            .get();

        _addLog(
            'Your bookings (worker_id = $myWorkerId): ${myBookings.docs.length}');

        if (myBookings.docs.isNotEmpty) {
          _addLog('\nYour bookings:');
          for (var doc in myBookings.docs) {
            var data = doc.data() as Map<String, dynamic>;
            _addLog('  📌 ${doc.id}');
            _addLog('     Customer: ${data['customer_name']}');
            _addLog('     Status: ${data['status']}');
            _addLog('     Worker ID in booking: ${data['worker_id']}');
          }
        }
      }
      _addLog('');

      // Check all chat rooms
      _addLog('💬 CHECKING CHAT ROOMS...\n');
      QuerySnapshot allChats =
          await FirebaseFirestore.instance.collection('chat_rooms').get();

      _addLog('Total chat rooms in database: ${allChats.docs.length}\n');

      if (myWorkerId != null) {
        QuerySnapshot myChats = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('worker_id', isEqualTo: myWorkerId)
            .get();

        _addLog('Your chats (worker_id = $myWorkerId): ${myChats.docs.length}');

        if (myChats.docs.isNotEmpty) {
          _addLog('\nYour chat rooms:');
          for (var doc in myChats.docs) {
            var data = doc.data() as Map<String, dynamic>;

            // Get message count
            QuerySnapshot messages = await FirebaseFirestore.instance
                .collection('chat_rooms')
                .doc(doc.id)
                .collection('messages')
                .get();

            _addLog('  💬 ${doc.id}');
            _addLog('     Booking: ${data['booking_id']}');
            _addLog('     Customer: ${data['customer_name']}');
            _addLog('     Worker ID in chat: ${data['worker_id']}');
            _addLog('     Messages: ${messages.docs.length}');
            _addLog('     Last message: ${data['last_message']}');
          }
        } else {
          _addLog('⚠️ No chats found for your worker_id');

          // Check if there are chats with Firebase UID instead
          QuerySnapshot chatsWithUid = await FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('worker_id', isEqualTo: user.uid)
              .get();

          if (chatsWithUid.docs.isNotEmpty) {
            _addLog('');
            _addLog('❌ PROBLEM FOUND:');
            _addLog(
                '   Found ${chatsWithUid.docs.length} chats using your Firebase UID instead of worker_id!');
            _addLog('   This means the chats were created before the fix.');
            _addLog('   Run the cleanup tool to fix this.');
          }
        }
      }
      _addLog('');

      // Analyze all workers for consistency
      _addLog('🔍 ANALYZING WORKER CONSISTENCY...\n');
      QuerySnapshot allWorkers =
          await FirebaseFirestore.instance.collection('workers').get();

      Map<String, List<String>> workersByEmail = {};
      Map<String, List<String>> workersByPhone = {};

      for (var doc in allWorkers.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String email = data['email'] ?? '';
        String phone = data['phone_number'] ?? '';
        String workerId = data['worker_id'] ?? 'NONE';

        if (email.isNotEmpty) {
          workersByEmail.putIfAbsent(email, () => []);
          workersByEmail[email]!.add('$workerId (${doc.id})');
        }

        if (phone.isNotEmpty) {
          workersByPhone.putIfAbsent(phone, () => []);
          workersByPhone[phone]!.add('$workerId (${doc.id})');
        }
      }

      // Find duplicates
      int duplicateEmails = 0;
      int duplicatePhones = 0;

      for (var entry in workersByEmail.entries) {
        if (entry.value.length > 1) {
          duplicateEmails++;
          _addLog('⚠️ Duplicate email: ${entry.key}');
          for (var id in entry.value) {
            _addLog('   - $id');
          }
          _addLog('');
        }
      }

      for (var entry in workersByPhone.entries) {
        if (entry.value.length > 1) {
          duplicatePhones++;
          _addLog('⚠️ Duplicate phone: ${entry.key}');
          for (var id in entry.value) {
            _addLog('   - $id');
          }
          _addLog('');
        }
      }

      // Summary
      _addLog('========================================');
      _addLog('VERIFICATION SUMMARY');
      _addLog('========================================');
      _addLog('Total workers: ${allWorkers.docs.length}');
      _addLog('Total bookings: ${allBookings.docs.length}');
      _addLog('Total chats: ${allChats.docs.length}');
      _addLog('Duplicate emails: $duplicateEmails');
      _addLog('Duplicate phones: $duplicatePhones\n');

      if (myWorkerId != null) {
        QuerySnapshot myBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('worker_id', isEqualTo: myWorkerId)
            .get();

        QuerySnapshot myChats = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('worker_id', isEqualTo: myWorkerId)
            .get();

        _addLog('Your statistics:');
        _addLog('  Worker ID: $myWorkerId');
        _addLog('  Your bookings: ${myBookings.docs.length}');
        _addLog('  Your chats: ${myChats.docs.length}');

        // Check consistency
        bool hasInconsistency = false;

        // Check if any bookings use wrong worker_id
        QuerySnapshot bookingsWithUid = await FirebaseFirestore.instance
            .collection('bookings')
            .where('worker_id', isEqualTo: user.uid)
            .get();

        if (bookingsWithUid.docs.isNotEmpty && user.uid != myWorkerId) {
          hasInconsistency = true;
          _addLog(
              '\n  ⚠️ ${bookingsWithUid.docs.length} bookings use Firebase UID instead of worker_id');
        }

        // Check if any chats use wrong worker_id
        QuerySnapshot chatsWithUid = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('worker_id', isEqualTo: user.uid)
            .get();

        if (chatsWithUid.docs.isNotEmpty && user.uid != myWorkerId) {
          hasInconsistency = true;
          _addLog(
              '  ⚠️ ${chatsWithUid.docs.length} chats use Firebase UID instead of worker_id');
        }

        if (hasInconsistency) {
          _addLog('\n❌ INCONSISTENCY DETECTED!');
          _addLog('   Some records use Firebase UID, others use worker_id.');
          _addLog('   This will cause chats not to show up.');
          _addLog('   👉 Run the cleanup tool to fix this.');
        } else if (duplicateEmails > 0 || duplicatePhones > 0) {
          _addLog('\n⚠️ DUPLICATES DETECTED!');
          _addLog('   👉 Run the cleanup tool to remove duplicates.');
        } else {
          _addLog('\n✅ ALL GOOD! Your worker IDs are consistent.');
        }
      } else {
        if (duplicateEmails > 0 || duplicatePhones > 0) {
          _addLog('⚠️ DUPLICATES DETECTED!');
          _addLog('   👉 Run the cleanup tool to remove duplicates.');
        } else {
          _addLog('✅ No inconsistencies found in the database.');
        }
      }
    } catch (e) {
      _addLog('\n❌ ERROR: $e');
    } finally {
      setState(() => _isRunning = false);

      // Auto-scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Worker IDs'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            color: Colors.blue[100],
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[900]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This tool checks if worker_ids are consistent across your database',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
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
                      'What This Tool Does',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✓ Checks your worker profile\n'
                      '✓ Lists your bookings and chats\n'
                      '✓ Finds duplicate workers\n'
                      '✓ Detects inconsistent worker_ids\n'
                      '✓ Provides recommendations',
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
              onPressed: _isRunning ? null : _verifyWorkerIds,
              icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.play_arrow),
              label: Text(_isRunning ? 'Analyzing...' : 'Run Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                child: SelectableText(
                  _log.isEmpty
                      ? 'Press the button to start verification...'
                      : _log,
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
