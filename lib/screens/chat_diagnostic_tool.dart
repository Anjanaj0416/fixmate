// lib/screens/chat_diagnostic_tool.dart
// DIAGNOSTIC TOOL - Run this to see exactly what's wrong
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDiagnosticTool extends StatefulWidget {
  @override
  _ChatDiagnosticToolState createState() => _ChatDiagnosticToolState();
}

class _ChatDiagnosticToolState extends State<ChatDiagnosticTool> {
  final ScrollController _scrollController = ScrollController();
  String _diagnosticLog = '';
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _diagnosticLog += '$message\n';
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _diagnosticLog = '';
      _isRunning = true;
    });

    try {
      _log('========================================');
      _log('CHAT DIAGNOSTIC TOOL');
      _log('========================================\n');

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log('❌ No user logged in');
        return;
      }

      _log('👤 Current User:');
      _log('   Firebase UID: ${user.uid}');
      _log('   Email: ${user.email}\n');

      // Check worker profile
      _log('1️⃣ CHECKING WORKER PROFILE');
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      String? workerId;
      String? workerName;

      if (workerDoc.exists) {
        var data = workerDoc.data() as Map<String, dynamic>;
        workerId = data['worker_id'];
        workerName = data['worker_name'];
        _log('✅ Worker Profile Found');
        _log('   Worker ID (HM format): $workerId');
        _log('   Worker Name: $workerName');
      } else {
        _log('❌ No worker profile found');
      }
      _log('');

      // Check all chat rooms
      _log('2️⃣ CHECKING ALL CHAT ROOMS IN DATABASE');
      QuerySnapshot allChats =
          await FirebaseFirestore.instance.collection('chat_rooms').get();

      _log('📊 Total chat rooms: ${allChats.docs.length}\n');

      if (allChats.docs.isEmpty) {
        _log('❌ NO CHAT ROOMS EXIST');
        setState(() => _isRunning = false);
        return;
      }

      // List all chats
      _log('3️⃣ LISTING ALL CHATS:');
      for (var doc in allChats.docs) {
        var data = doc.data() as Map<String, dynamic>;
        _log('');
        _log('📨 Chat ID: ${doc.id}');
        _log('   Booking: ${data['booking_id']}');
        _log('   Customer: ${data['customer_name']} (${data['customer_id']})');
        _log('   Worker: ${data['worker_name']} (${data['worker_id']})');
        _log('   Last Message: ${data['last_message']}');

        // Check messages
        QuerySnapshot messages = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(doc.id)
            .collection('messages')
            .get();
        _log('   💬 Messages: ${messages.docs.length}');

        if (messages.docs.isNotEmpty) {
          _log('   📝 Sample messages:');
          for (var msg in messages.docs.take(3)) {
            var msgData = msg.data() as Map<String, dynamic>;
            _log(
                '      - "${msgData['message']}" from ${msgData['sender_name']}');
          }
        }
      }
      _log('');

      // Check for matching chats
      if (workerId != null) {
        _log('4️⃣ CHECKING FOR MATCHES WITH YOUR WORKER_ID');
        _log('   Your worker_id: $workerId');
        _log('   Your Firebase UID: ${user.uid}\n');

        // Method 1: Query by worker_id field
        _log('Method 1: Querying by worker_id = $workerId');
        QuerySnapshot matchByWorkerId = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('worker_id', isEqualTo: workerId)
            .get();
        _log('   Found: ${matchByWorkerId.docs.length} chats');

        // Method 2: Query by Firebase UID
        _log('\nMethod 2: Querying by worker_id = ${user.uid}');
        QuerySnapshot matchByUid = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('worker_id', isEqualTo: user.uid)
            .get();
        _log('   Found: ${matchByUid.docs.length} chats');

        // Check what worker_id values actually exist
        _log('\n5️⃣ ANALYZING WORKER_ID VALUES IN CHATS:');
        Set<String> uniqueWorkerIds = {};
        for (var doc in allChats.docs) {
          var data = doc.data() as Map<String, dynamic>;
          uniqueWorkerIds.add(data['worker_id'] ?? 'NULL');
        }
        _log('   Unique worker_id values found:');
        for (var id in uniqueWorkerIds) {
          _log('      - "$id"');
        }

        _log('\n6️⃣ COMPARISON:');
        _log('   Your worker_id: "$workerId"');
        _log('   Your Firebase UID: "${user.uid}"');
        _log(
            '   Match with worker_id? ${uniqueWorkerIds.contains(workerId) ? "✅ YES" : "❌ NO"}');
        _log(
            '   Match with UID? ${uniqueWorkerIds.contains(user.uid) ? "✅ YES" : "❌ NO"}');

        if (!uniqueWorkerIds.contains(workerId) &&
            !uniqueWorkerIds.contains(user.uid)) {
          _log('\n❌ PROBLEM IDENTIFIED:');
          _log('   Your worker_id ($workerId) does not match any');
          _log('   worker_id values in the chat_rooms collection!');
          _log('\n💡 SOLUTION:');
          _log('   The chat rooms were created with a different worker_id.');
          _log('   You need to either:');
          _log('   1. Update the chat rooms to use your current worker_id');
          _log('   2. Update your worker profile to match the chat rooms');
        }
      }

      _log('\n========================================');
      _log('DIAGNOSTIC COMPLETE');
      _log('========================================');
    } catch (e) {
      _log('\n❌ ERROR: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Diagnostic Tool'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'This tool will check why chats are not displaying',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runDiagnostics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isRunning ? 'Running Diagnostics...' : 'Run Diagnostics',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Container(
              color: Colors.black,
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  _diagnosticLog.isEmpty
                      ? 'Press "Run Diagnostics" to start...'
                      : _diagnosticLog,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _diagnosticLog.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _diagnosticLog = '';
                });
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.clear),
            )
          : null,
    );
  }
}
