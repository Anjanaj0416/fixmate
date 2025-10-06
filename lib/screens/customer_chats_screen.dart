// lib/screens/customer_chats_screen.dart
// FIXED VERSION - Properly loads customer ID and displays chats
// Modified: Added soft light-blue and white gradient background
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'admin_support_chat_screen.dart';

class CustomerChatsScreen extends StatefulWidget {
  @override
  _CustomerChatsScreenState createState() => _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends State<CustomerChatsScreen> {
  User? _currentUser;
  String? _customerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    setState(() => _isLoading = true);

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      try {
        // Try to get customer by UID first
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(_currentUser!.uid)
            .get();

        if (customerDoc.exists) {
          setState(() {
            _customerId =
                (customerDoc.data() as Map<String, dynamic>)['customer_id'] ??
                    _currentUser!.uid;
            _isLoading = false;
          });
          print('✅ Customer loaded: $_customerId');
          return;
        }

        // If not found by UID, try by email
        QuerySnapshot customerQuery = await FirebaseFirestore.instance
            .collection('customers')
            .where('email', isEqualTo: _currentUser!.email)
            .limit(1)
            .get();

        if (customerQuery.docs.isNotEmpty) {
          setState(() {
            _customerId = (customerQuery.docs.first.data()
                    as Map<String, dynamic>)['customer_id'] ??
                customerQuery.docs.first.id;
            _isLoading = false;
          });
          print('✅ Customer loaded by email: $_customerId');
        } else {
          print('❌ Customer not found');
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('❌ Error loading customer: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _openAdminSupport() {
    if (_customerId == null) {
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
          userName: _currentUser!.displayName ?? 'Customer',
          userType: 'customer',
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
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFE3F2FD), // Light blue
              ],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentUser == null || _customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Chats'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFE3F2FD), // Light blue
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
                  'Could not load customer profile',
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
        backgroundColor: Colors.blue,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFE3F2FD), // Light blue
            ],
          ),
        ),
        child: Column(
          children: [
            // Support Button Banner
            Container(
              width: double.infinity,
              color: Colors.green[50],
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
            // Chat List
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
                  print('✅ Displaying ${chats.length} chats');

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      ChatRoom chat = chats[index];
                      bool hasUnread = chat.unreadCountCustomer > 0;

                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: hasUnread ? 4 : 1,
                        color: hasUnread ? Colors.blue[50] : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.workerName,
                                  style: TextStyle(
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                                    '${chat.unreadCountCustomer}',
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
                                'Booking #${chat.bookingId.substring(0, 8)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            _formatTimestamp(chat.lastMessageTime),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
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
