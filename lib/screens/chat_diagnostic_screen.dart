// lib/screens/chat_diagnostic_screen.dart
// DIAGNOSTIC TOOL - Add this screen to debug chat issues
// Access it from your dashboard or add a button to test

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDiagnosticScreen extends StatefulWidget {
  @override
  _ChatDiagnosticScreenState createState() => _ChatDiagnosticScreenState();
}

class _ChatDiagnosticScreenState extends State<ChatDiagnosticScreen> {
  final TextEditingController _outputController = TextEditingController();
  bool _isRunning = false;

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _outputController.text += '$message\n';
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _outputController.text =
          '🔍 STARTING CHAT DIAGNOSTICS\n' + '=' * 50 + '\n\n';
    });

    try {
      // 1. Check current user
      _log('1️⃣ CHECKING CURRENT USER');
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log('❌ No user logged in!');
        setState(() => _isRunning = false);
        return;
      }
      _log('✅ User ID: ${user.uid}');
      _log('✅ Email: ${user.email}');
      _log('');

      // 2. Check if user is customer or worker
      _log('2️⃣ CHECKING USER PROFILE');

      // Check customer collection
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      String? customerId;
      String? customerName;
      if (customerDoc.exists) {
        var data = customerDoc.data() as Map<String, dynamic>;
        customerId = data['customer_id'] ?? user.uid;
        customerName = data['customer_name'] ??
            '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        _log('✅ CUSTOMER PROFILE FOUND');
        _log('   Customer ID: $customerId');
        _log('   Customer Name: $customerName');
      } else {
        _log('⚠️ Not found in customers collection');
      }
      _log('');

      // Check worker collection
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      String? workerId;
      String? workerName;
      if (workerDoc.exists) {
        var data = workerDoc.data() as Map<String, dynamic>;
        workerId = data['worker_id'] ?? user.uid;
        workerName = data['worker_name'];
        _log('✅ WORKER PROFILE FOUND');
        _log('   Worker ID: $workerId');
        _log('   Worker Name: $workerName');
      } else {
        _log('⚠️ Not found in workers collection');
      }
      _log('');

      // 3. Check all chat rooms in database
      _log('3️⃣ CHECKING ALL CHAT ROOMS');
      QuerySnapshot allChats =
          await FirebaseFirestore.instance.collection('chat_rooms').get();

      _log('📊 Total chat rooms: ${allChats.docs.length}');
      _log('');

      if (allChats.docs.isEmpty) {
        _log('❌ NO CHAT ROOMS EXIST IN DATABASE!');
        _log('   This means no chats have been created yet.');
        setState(() => _isRunning = false);
        return;
      }

      // 4. List all chat rooms with details
      _log('4️⃣ LISTING ALL CHAT ROOMS:');
      for (var doc in allChats.docs) {
        var data = doc.data() as Map<String, dynamic>;
        _log('');
        _log('📨 Chat ID: ${doc.id}');
        _log('   Booking: ${data['booking_id']}');
        _log('   Customer ID: ${data['customer_id']}');
        _log('   Customer Name: ${data['customer_name']}');
        _log('   Worker ID: ${data['worker_id']}');
        _log('   Worker Name: ${data['worker_name']}');
        _log('   Last Message: ${data['last_message']}');
        _log('   Unread (Customer): ${data['unread_count_customer']}');
        _log('   Unread (Worker): ${data['unread_count_worker']}');

        // Check messages in this chat
        QuerySnapshot messages = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(doc.id)
            .collection('messages')
            .get();
        _log('   💬 Messages: ${messages.docs.length}');
      }
      _log('');

      // 5. Check for matching chats
      _log('5️⃣ CHECKING FOR USER\'S CHATS:');

      if (customerId != null) {
        _log('');
        _log('🔍 Searching chats WHERE customer_id = $customerId');
        QuerySnapshot customerChats = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('customer_id', isEqualTo: customerId)
            .get();
        _log('   Found: ${customerChats.docs.length} chats');

        if (customerChats.docs.isEmpty) {
          _log('   ❌ NO MATCHES!');
          _log(
              '   ⚠️ This means the customer_id in chat_rooms doesn\'t match!');
          _log('');
          _log('   💡 SOLUTION: Check if chat rooms have:');
          _log('      - Different customer_id format');
          _log('      - Or customer_id was created incorrectly');
        } else {
          for (var doc in customerChats.docs) {
            _log('   ✅ Match: ${doc.id}');
          }
        }
      }

      if (workerId != null) {
        _log('');
        _log('🔍 Searching chats WHERE worker_id = $workerId');
        QuerySnapshot workerChats = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('worker_id', isEqualTo: workerId)
            .get();
        _log('   Found: ${workerChats.docs.length} chats');

        if (workerChats.docs.isEmpty) {
          _log('   ❌ NO MATCHES!');
          _log('   ⚠️ This means the worker_id in chat_rooms doesn\'t match!');
          _log('');
          _log('   💡 SOLUTION: Check if chat rooms have:');
          _log('      - Different worker_id format');
          _log('      - Or worker_id was created incorrectly');
        } else {
          for (var doc in workerChats.docs) {
            _log('   ✅ Match: ${doc.id}');
          }
        }
      }

      _log('');
      _log('=' * 50);
      _log('✅ DIAGNOSTICS COMPLETE!');
    } catch (e) {
      _log('');
      _log('❌ ERROR DURING DIAGNOSTICS:');
      _log('$e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Diagnostics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat System Diagnostics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This tool will check:\n'
                      '• Your user profile\n'
                      '• All chat rooms in database\n'
                      '• ID matching issues\n'
                      '• Message counts',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runDiagnostics,
              icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.play_arrow),
              label: Text(_isRunning ? 'Running...' : 'Run Diagnostics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _outputController,
                  maxLines: null,
                  readOnly: true,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.green[300],
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    hintText: 'Diagnostic output will appear here...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _outputController.clear();
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Clear'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Copy to clipboard
                      // You'd need to add clipboard package for this
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Copy functionality - add clipboard package')),
                      );
                    },
                    icon: Icon(Icons.copy),
                    label: Text('Copy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
