// lib/screens/customer_chats_screen.dart
// MODIFIED VERSION - Added Online Status Indicator for Workers
// Shows green dot when worker is online, gray when offline

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'chat_diagnostic_screen.dart';

class CustomerChatsScreen extends StatefulWidget {
  @override
  _CustomerChatsScreenState createState() => _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends State<CustomerChatsScreen> {
  String? _customerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        setState(() => _isLoading = false);
        return;
      }

      print('🔍 Loading customer ID for user: ${user.uid}');

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
        setState(() {
          _customerId = data['customer_id'] ?? user.uid;
          _isLoading = false;
        });
        print('✅ Customer ID loaded: $_customerId');
      } else {
        print('⚠️ Customer document not found, using UID as fallback');
        setState(() {
          _customerId = user.uid;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading customer ID: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showDiagnosticDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatDiagnosticScreen()),
    );
  }

  // NEW: Stream to get worker's online status
  Stream<bool> _getWorkerOnlineStatus(String workerId) {
    return FirebaseFirestore.instance
        .collection('workers')
        .where('worker_id', isEqualTo: workerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return false;
      var data = snapshot.docs.first.data();
      return data['is_online'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Chats'),
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFE5CC)],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Chats'),
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFE5CC)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Unable to load customer profile',
                  style: TextStyle(fontSize: 16),
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
        backgroundColor: Color(0xFFFF9800),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showDiagnosticDialog,
            tooltip: 'Diagnostic Info',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFE5CC)],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(
                  bottom: BorderSide(color: Colors.green[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need help? Contact Admin Support',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Support',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatRoom>>(
                stream: ChatService.getCustomerChatsStream(_customerId!),
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
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print('📭 No chats found for customer: $_customerId');
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
                            'Start chatting with workers\nthrough your bookings',
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
                  print('💬 Displaying ${chats.length} chats');

                  return ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      ChatRoom chat = chats[index];
                      bool hasUnread = chat.unreadCountCustomer > 0;

                      // NEW: Wrap with StreamBuilder for online status
                      return StreamBuilder<bool>(
                        stream: _getWorkerOnlineStatus(chat.workerId),
                        builder: (context, onlineSnapshot) {
                          bool isOnline = onlineSnapshot.data ?? false;

                          return Card(
                            elevation: hasUnread ? 4 : 1,
                            margin: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            color: hasUnread ? Colors.blue[50] : Colors.white,
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child:
                                        Icon(Icons.person, color: Colors.white),
                                  ),
                                  // NEW: Online Status Indicator
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: isOnline
                                            ? [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.5),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : [],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.workerName,
                                      style: TextStyle(
                                        fontWeight: hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // NEW: Show "Online" badge
                                  if (isOnline)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Online',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: hasUnread
                                      ? Colors.blue[900]
                                      : Colors.grey[600],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(chat.lastMessageTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          hasUnread ? Colors.blue : Colors.grey,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (hasUnread) ...[
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${chat.unreadCountCustomer}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                print('💬 Opening chat: ${chat.chatId}');
                                print('   Worker: ${chat.workerName}');
                                print('   Booking: ${chat.bookingId}');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chat.chatId,
                                      bookingId: chat.bookingId,
                                      otherUserName: chat.workerName,
                                      currentUserType: 'customer',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
