// lib/screens/worker_chats_screen.dart
// FIXED VERSION with built-in diagnostic and back button
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'admin_support_chat_screen.dart';

class WorkerChatsScreen extends StatefulWidget {
  @override
  _WorkerChatsScreenState createState() => _WorkerChatsScreenState();
}

class _WorkerChatsScreenState extends State<WorkerChatsScreen> {
  User? _currentUser;
  String? _workerId;
  String? _workerUid;
  bool _isLoading = true;
  String _diagnosticInfo = '';

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      try {
        _workerUid = _currentUser!.uid;

        // Try to get worker by UID first
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(_currentUser!.uid)
            .get();

        if (workerDoc.exists) {
          var data = workerDoc.data() as Map<String, dynamic>;
          setState(() {
            _workerId = data['worker_id'] ?? _currentUser!.uid;
            _isLoading = false;
          });
          print('✅ Worker loaded: $_workerId (UID: $_workerUid)');

          // Run diagnostic
          await _runQuickDiagnostic();
          return;
        }

        // If not found by UID, try by email
        QuerySnapshot workerQuery = await FirebaseFirestore.instance
            .collection('workers')
            .where('contact.email', isEqualTo: _currentUser!.email)
            .limit(1)
            .get();

        if (workerQuery.docs.isNotEmpty) {
          var data = workerQuery.docs.first.data() as Map<String, dynamic>;
          setState(() {
            _workerId = data['worker_id'] ?? workerQuery.docs.first.id;
            _isLoading = false;
          });
          print('✅ Worker loaded by email: $_workerId (UID: $_workerUid)');
          await _runQuickDiagnostic();
        } else {
          print('❌ Worker not found');
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('❌ Error loading worker: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runQuickDiagnostic() async {
    if (_workerId == null) return;

    try {
      // Check all chat rooms
      QuerySnapshot allChats =
          await FirebaseFirestore.instance.collection('chat_rooms').get();

      // Check for matches
      int matchCount = 0;
      List<String> sampleWorkerIds = [];

      for (var doc in allChats.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String chatWorkerId = data['worker_id'] ?? 'no_id';

        if (!sampleWorkerIds.contains(chatWorkerId) &&
            sampleWorkerIds.length < 5) {
          sampleWorkerIds.add(chatWorkerId);
        }

        if (chatWorkerId == _workerId || chatWorkerId == _workerUid) {
          matchCount++;
        }
      }

      setState(() {
        _diagnosticInfo = '''
Your worker_id: $_workerId
Your UID: $_workerUid
Total chat rooms: ${allChats.docs.length}
Matching chats: $matchCount
Sample worker_ids in DB: ${sampleWorkerIds.join(', ')}
''';
      });

      print('📊 Quick Diagnostic:');
      print(_diagnosticInfo);
    } catch (e) {
      print('❌ Diagnostic error: $e');
    }
  }

  void _showDiagnosticDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Diagnostic Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _diagnosticInfo.isEmpty
                    ? 'No diagnostic data available.\nTap Refresh to run diagnostic.'
                    : _diagnosticInfo,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              SizedBox(height: 16),
              if (_diagnosticInfo.contains('Matching chats: 0'))
                Text(
                  '⚠️ Problem: Your worker_id doesn\'t match any chats. The chats were created with a different worker_id.',
                  style: TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runQuickDiagnostic();
            },
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _openAdminSupport() {
    if (_workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading user data, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSupportChatScreen(
          userId: _currentUser!.uid,
          userName: _currentUser!.displayName ?? 'Worker',
          userType: 'worker',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Chats'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFFFE5CC), // Light orange at bottom
              ],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentUser == null || _workerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Chats'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFFFE5CC), // Light orange at bottom
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Could not load worker profile',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Chats'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent),
            tooltip: 'Contact Admin Support',
            onPressed: _openAdminSupport,
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: 'Show Diagnostic',
            onPressed: _showDiagnosticDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFE5CC), // Light orange at bottom
            ],
          ),
        ),
        child: Column(
          children: [
            // Support Button Banner - Changed to light green
            Container(
              width: double.infinity,
              color: Colors
                  .lightGreen[100], // Changed from orange[50] to light green
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.green[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Need help? Contact Admin Support',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openAdminSupport,
                    child: Text('Support'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),

            // Debug Info Banner (only show if no matches)
            if (_diagnosticInfo.isNotEmpty &&
                _diagnosticInfo.contains('Matching chats: 0'))
              Container(
                width: double.infinity,
                color: Colors.red[50],
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debug: No matching chats found. Tap bug icon for details.',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Chat List
            Expanded(
              child: StreamBuilder<List<ChatRoom>>(
                stream: ChatService.getWorkerChatsStreamWithBothIds(
                  _workerId!,
                  _workerUid!,
                ),
                builder: (context, snapshot) {
                  print('🔄 Stream state: ${snapshot.connectionState}');

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('❌ Stream error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading chats',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print('📭 No chats found for worker: $_workerId');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No chats yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start chatting with customers\nthrough your bookings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _showDiagnosticDialog,
                            icon: Icon(Icons.bug_report),
                            label: Text('Show Diagnostic Info'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  List<ChatRoom> chats = snapshot.data!;
                  print('💬 Displaying ${chats.length} chats');

                  return ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      ChatRoom chat = chats[index];
                      bool hasUnread = chat.unreadCountWorker > 0;

                      return Card(
                        elevation: hasUnread ? 4 : 1,
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: hasUnread ? Colors.orange[50] : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.customerName,
                                  style: TextStyle(
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${chat.unreadCountWorker}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatTimestamp(chat.lastMessageTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chat.chatId,
                                  bookingId: chat.bookingId,
                                  otherUserName: chat.customerName,
                                  currentUserType: 'worker',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
