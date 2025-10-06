// lib/screens/worker_chats_screen.dart
// FIXED VERSION - Now checks both worker_id and UID when loading chats
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
          automaticallyImplyLeading: false,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null || _workerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Chats'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Center(
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Chats'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent),
            tooltip: 'Contact Admin Support',
            onPressed: _openAdminSupport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Support Button Banner
          Container(
            width: double.infinity,
            color: Colors.orange[50],
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.help_outline, color: Colors.orange[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Need help? Contact Admin Support',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openAdminSupport,
                  child: Text('Support'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              // FIXED: Now passes both worker_id and UID
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
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                      ],
                    ),
                  );
                }

                List<ChatRoom> chats = snapshot.data!;

                return ListView.builder(
                  itemCount: chats.length,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    ChatRoom chat = chats[index];
                    bool hasUnread = chat.unreadCountWorker > 0;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: hasUnread ? 3 : 1,
                      color: hasUnread ? Colors.blue[50] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            chat.customerName.isNotEmpty
                                ? chat.customerName[0].toUpperCase()
                                : 'C',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.customerName,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
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
                            Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Booking: ${chat.bookingId.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatTime(chat.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
    );
  }

  String _formatTime(DateTime time) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
